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

## Integración (alcance de esta entrega)

- Tabla + vista + volcado (este script).
- Pantalla `inMtoEmpleados` + data module `UniDataEmpleados`, registrados en
  `fzam.dproj`, `fza_winforms` y el menú (junto a Usuarios, en
  *Usuarios, Grupos y Perfiles*).

## Pendiente (fuera de alcance, decisión del usuario)

Repuntar los **selectores de empleado** de caja/traspasos/arqueos para que lean
de `fza_empleados` en lugar de `fza_usuarios`. Hoy siguen leyendo de usuarios
(no se ha tocado). Puntos a repuntar cuando se aborde:

- `src/Caja/Forms/inMtoCajaOpe.pas` (validar y buscar empleado)
- `src/Caja/DataModules/UniDataCaja.pas` (diminutivo para el ticket)
- `src/Caja/Modals/inMtoModalGastoCaja.pas`, `src/Modals/inMtoModalEntradaCambio.pas`
- `src/Forms/inMtoTraspasoOpe.pas`, `src/DataModules/UniDataTraspaso.pas`
- Arqueos: `src/Caja/Lib/inLibArqueoTicket.pas`, `src/Caja/Modals/inMtoModalArqueo.pas`
