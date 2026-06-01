# Permisos

Sistema de permisos por **usuario / grupo / Todos**, paralelo a los perfiles
(`fza_usuarios_perfiles`). Esta nota acompaña a `permisos.sql`.

## Modelo de datos — `fza_permisos`

| Columna              | Tipo          | Notas                                  |
|----------------------|---------------|----------------------------------------|
| `USUARIO_GRUPO_PERM` | varchar(200)  | Usuario, grupo o `'Todos'`. Parte 1 PK |
| `CODIGO_PERM`        | varchar(60)   | Clave del permiso. Parte 2 PK          |
| `VALOR_PERM`         | varchar(1)    | `'S'` / `'N'`                          |
| `DESCRIPCION_PERM`   | varchar(200)  | Texto para el Mto                      |

Antes la columna principal se llamaba `GRUPO_PERM` (varchar(50), solo grupo).
`permisos.sql` la renombra a `USUARIO_GRUPO_PERM` y la ensancha a varchar(200)
de forma idempotente (guardado por `INFORMATION_SCHEMA`, `CHANGE COLUMN`).

## Convención de códigos (`CODIGO_PERM`)

- `menu.<CALL_WINF>`        → acceso al item de menú (lo aplica
  `inMtoPrincipal.AplicarPermisosMenu`, oculta el menú si está denegado).
- `accion.<algo>`           → acciones globales de los mantenimientos.
- `arqueo.<algo>` / `caja.<algo>` → permisos específicos de caja/arqueo.

## Resolución (runtime) — `inLibPermisos`

`oPermisos.TienePermiso(codigo, default)` resuelve por prioridad:

1. **Administrador** (`oRootGroup = 'S'`) → siempre `True`.
2. **Usuario** (`oUser`).
3. **Grupo** (`oGroup`).
4. **`'Todos'`**.
5. Si no hay fila → `default` (parámetro de la llamada).

La caché se precarga al login (`Precargar`) trayendo solo las filas de
`USUARIO_GRUPO_PERM IN (usuario, grupo, 'Todos')`.

## Pantalla — `inMtoPermisos`

- Form `inMtoPermisos.TfrmMtoPermisos` (hereda `TfrmMtoGen`), grid editable
  igual que Perfiles: columnas `Usuario / Grupo`, `Código`, `Valor`,
  `Descripción`.
- Data module reutilizado: `UniDataPermisosGrupo.TdmPermisosGrupo`.
- Registrada en `fza_winforms` (CALL `Permisos`, item `mnuPermisos`) por
  `permisos.sql`. Menú: junto a Usuarios / Grupos / Perfiles.

## Aplicar a una BBDD existente

```sql
SOURCE DESARROLLOS EN CURSO/permisos.sql;
```

Idempotente: se puede relanzar sin efectos secundarios.
