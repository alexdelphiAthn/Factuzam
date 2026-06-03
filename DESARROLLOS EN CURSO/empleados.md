# Empleados (fza_empleados)

Tabla maestra de **empleados** = operarios que se estampan en caja, traspasos
y arqueos. Independiente de `fza_usuarios` (el login): un empleado y un usuario
**pueden ser distintos**.

## Por qué

Hoy la identidad del operario vive incrustada en `fza_usuarios`:

| Columna en fza_usuarios | Concepto                                   |
|-------------------------|--------------------------------------------|
| `CODIGO_EMPLEADO_USU`   | Número de empleado en caja                 |
| `DIMINUTIVO_TICKET_USU` | Diminutivo de caja / abreviatura de ticket |

Eso obliga a que todo operario tenga usuario de login y no permite guardar sus
datos personales (nombre, dirección, teléfono). Las tablas operativas ya
guardan el **código de empleado** suelto, no el usuario:

- `fza_caja_operaciones.CODIGO_EMPLEADO_OPCAJA`
- `fza_caja_arqueos.CODIGO_EMPLEADO_ARQ`
- `fza_traspasos_solicitudes.CODIGO_EMPLEADO_TRSOL`
- `fza_facturas.CODIGO_CAJERO_FAC`

`fza_empleados` saca ese concepto a tabla propia.

## Auditoría ≠ empleado

`USUARIO_ALTA` / `USUARIO_MODIF` de **todas** las tablas (incluida
`fza_empleados`) las sella automáticamente `TdmConn.ActualizarUserTimeModif`
(`src/DataModules/UniDataConn.pas`) con `inLibGlobalVar.oUser` = el **usuario
logado**. La auditoría es siempre del usuario; el empleado es otra cosa.

## Esquema

`fza_empleados` (sufijo `EMPL`; `EMP` ya es de `fza_empresas`):

| Columna                  | Tipo         | Notas                          |
|--------------------------|--------------|--------------------------------|
| `CODIGO_EMPL` (PK)       | varchar(20)  | Número de empleado en caja     |
| `NOMBRE_EMPL`            | varchar(100) | Dato básico                    |
| `DIRECCION_EMPL`         | varchar(200) | Dato básico                    |
| `TELEFONO_EMPL`          | varchar(20)  | Dato básico                    |
| `DIMINUTIVO_TICKET_EMPL` | varchar(10)  | Diminutivo de caja (ticket)    |
| `ESACTIVO_EMPL`          | char(1)      | S/N, def. 'S'                  |
| auditoría (4 columnas)   |              | = usuario logado               |

Vista `vi_empleados` (passthrough). La pantalla lee de la vista y escribe sobre
la tabla, igual que `inMtoUsuarios` / `vi_usuarios`.

## Volcado inicial

El script vuelca desde `fza_usuarios` cada fila con `CODIGO_EMPLEADO_USU`:
`CODIGO_EMPL := CODIGO_EMPLEADO_USU`, `DIMINUTIVO_TICKET_EMPL :=
DIMINUTIVO_TICKET_USU`, `ESACTIVO_EMPL := ESACTIVO_USU`. `NOMBRE_EMPL` se
siembra provisionalmente con `USUARIO_USU` para que la fila no quede sin nombre;
se edita después en la pantalla. `INSERT IGNORE` → idempotente.

## Fase 1 — tabla y pantalla (este script)

- Tabla + vista + volcado (`empleados.sql`).
- Pantalla `inMtoEmpleados` + data module `UniDataEmpleados`, registrados en
  `fzam.dproj`, `fza_winforms` y el menú (junto a Usuarios, en
  *Usuarios, Grupos y Perfiles*).

## Fase 2 — repunte a fza_empleados y retirada de fza_usuarios

Script: `empleados_retirar_columnas_usuarios.sql` (rollback sin pérdida en
`empleados_retirar_columnas_usuarios_rollback.sql`).

Caja, traspasos y arqueos ya **leen de `fza_empleados`** (no de `fza_usuarios`):

- `src/Caja/Forms/inMtoCajaOpe.pas` (validar y buscar empleado/cajero).
- `src/Caja/DataModules/UniDataCaja.pas` (diminutivo para el ticket).
- `src/Caja/Modals/inMtoModalGastoCaja.pas`, `src/Modals/inMtoModalEntradaCambio.pas`.
- `src/Forms/inMtoTraspasoOpe.pas`, `src/DataModules/UniDataTraspaso.pas`.
- Arqueos: el resumen por empleado (`inLibArqueoTicket.pas` y `inMtoModalArqueo.pas`)
  hace `LEFT JOIN fza_empleados` y muestra el diminutivo del empleado; si el
  código no existe en `fza_empleados`, cae al código sin más (COALESCE).

Y se **retiran de `fza_usuarios`** las dos columnas, que ya viven en
`fza_empleados`:

- `CODIGO_EMPLEADO_USU`
- `DIMINUTIVO_TICKET_USU`

El script recrea `vi_usuarios` sin esas columnas, guarda el mapeo
`USUARIO_USU -> (código, diminutivo)` en `fza_usuarios_empl_bak` para el
rollback, limpia la config de columnas visibles de esas dos columnas y la
pantalla de Usuarios (`inMtoUsuarios` / `UniDataUsuarios`) deja de mostrarlas
y editarlas.

### Orden de aplicación

1. `empleados.sql` (fase 1, si no se aplicó aún).
2. `empleados_retirar_columnas_usuarios.sql` (fase 2).
