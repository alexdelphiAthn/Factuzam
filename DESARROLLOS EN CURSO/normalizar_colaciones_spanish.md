# Fix: mezcla de colaciones (1267) al entrar en Arqueos

## Problema

Al entrar en el Arqueo (F11 del menú de caja, `lblArqueo`) salta:

```
EMySqlNetException [1267]
#HY000Illegal mix of collations (utf8mb4_uca1400_ai_ci,IMPLICIT)
and (utf8mb4_spanish_ci,IMPLICIT) for operation '='
```

Stack: `TfrmModalArqueo.Recalcular` → `RefrescarResumenes` →
`AbrirQryConParams` (el primer query que abre es `qryResEmpleado`).

## Causa raíz

MariaDB ≥ 11.2 mapea el charset `utf8mb4` a la colación
`utf8mb4_uca1400_ai_ci` (variable `character_set_collations`). Todo
`CREATE TABLE … DEFAULT CHARSET=utf8mb4` **sin `COLLATE` explícito**
crea la tabla con esa colación, mientras el resto de la BBDD usa
`utf8mb4_spanish_ci`. También puede aparecer `utf8`/`utf8mb3` si una
copia antigua se importó sin charset/collation explícitos. Tablas
afectadas detectadas inicialmente (todas de scripts de
`DESARROLLOS EN CURSO/`):

| Tabla | Script que la creó |
|---|---|
| `fza_empleados` | `empleados.sql` |
| `fza_caja_arqueos` | `arqueo_caja.sql` |
| `fza_caja_arqueos_recuento` | `arqueo_recuento.sql` |
| `fza_permisos` | `permisos.sql` |
| `fza_informes_guias` | `informes_guias.sql` |
| `fza_inventarios_recuentos` | `recuento_inventarios_factuzam.sql` |
| `fza_usuarios_empl_bak` | `empleados_retirar_columnas_usuarios.sql` |

El resumen por empleado del arqueo (`qryResEmpleado` en
`inMtoModalArqueo.pas`) hace
`JOIN fza_empleados e ON e.CODIGO_EMPL = o.CODIGO_EMPLEADO_OPCAJA`:
columna `uca1400` contra columna `spanish_ci`, ambas con coercibilidad
IMPLICIT → ninguna gana → error 1267.

El `SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci` que ya aplica
`TdmConn` al conectar no cubre este caso: arregla literales, parámetros
y derivadas (CTE/UNION), pero no la colación **física** de las columnas.

## Solución

1. **`normalizar_colaciones_spanish.sql`** (nuevo, idempotente): fija el
   default de la BBDD a `utf8mb4_spanish_ci` y convierte con
   `ALTER TABLE … CONVERT TO CHARACTER SET utf8mb4 COLLATE
   utf8mb4_spanish_ci` toda tabla base del esquema con otra colación,
   incluidas tablas `utf8`/`utf8mb3` (cursor sobre
   `INFORMATION_SCHEMA.TABLES`, mismo patrón de procedimiento que
   `indices_busqueda_skus.sql`). Normalmente tarda segundos si solo
   reconstruye las 7 tablas pequeñas de arriba; en copias antiguas con
   muchas tablas `utf8mb3` puede tardar más. Termina con un SELECT de
   verificación que debe devolver 0 filas.

2. **Scripts corregidos** añadiendo `COLLATE=utf8mb4_spanish_ci` al
   `CREATE TABLE`, para que instalaciones nuevas no reproduzcan el
   problema: los 7 de la tabla anterior y
   `recuento_inventarios_servidor.sql` (5 tablas `inv_*` del servidor de
   inventarios, BBDD aparte; ahí no había choque porque solo se
   relacionan entre sí, se alinea por uniformidad).

## Pendiente / notas

- `factuzam_original.sql` **no se toca** (regla del repo). El dump del
  11/06/2026 arrastra las 7 tablas sin `COLLATE`: cuando el usuario lo
  regenere después de aplicar este script, saldrán ya con
  `COLLATE=utf8mb4_spanish_ci`. Hasta entonces, en una instalación
  limpia sobre MariaDB ≥ 11.2 hay que pasar este script tras el dump.
- Los scripts con `ENGINE=InnoDB` sin charset
  (`optimizar_recalculo_pmp.sql`, `fix_stock_desde_inventario_migrado.sql`)
  heredan el default de la BBDD; con el paso 1 del script quedan
  cubiertos.

## Verificación

Aplicado el script en FAUSTINO: entrar en Caja → Arqueo (F11) y
comprobar que cargan las pestañas Arqueo/Resúmenes/Más datos sin 1267.
El SELECT final del script debe devolver 0 filas.
