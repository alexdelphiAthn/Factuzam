# Permisos de Contazam

Los permisos se conceden a grupos. Un usuario recibe la suma de los permisos
de todos sus grupos activos. No hay denegaciones explícitas: si no existe una
concesión aplicable, el acceso se rechaza.

## Campos

- `RECURSO_GPE`: pantalla o listado protegido. `*` abarca todos.
- `ACCION_GPE`: operación autorizada. `*` abarca todas.
- `ALCANCE_GPE`: `GLOBAL` o `EMPRESA`.
- `CODIGO_EMP_GPE`: `*` para alcance global o el código de empresa.
- `ESACTIVO_GPE`: `S` activa la concesión y `N` la conserva desactivada.

La clave completa permite que un mismo grupo tenga varios alcances sobre el
mismo recurso y acción. La pantalla de seguridad solo puede abrirla un usuario
con permiso global `SEGURIDAD/ADMINISTRAR`.

## Recursos de pantalla

- `EMPRESAS`, `EJERCICIOS`, `PLAN_CONTABLE`.
- `LIBRO_DIARIO`, `LIBRO_MAYOR`, `CONTADORES`.
- `ARCHIVO_DOCUMENTAL`, `IMPORTACION_FACTURAS`.
- `LISTADOS`, `SEGURIDAD`.

La acción usada para abrir estas pantallas es `ABRIR`. La administración de
usuarios, grupos y permisos usa además `SEGURIDAD/ADMINISTRAR`.

## Recursos de listado

| Recurso | Listado |
| --- | --- |
| `LISTADO_BALANCE` | Balance de sumas y saldos |
| `LISTADO_DIARIO` | Libro diario |
| `LISTADO_MAYOR` | Libro mayor |
| `LISTADO_BORRADORES` | Asientos pendientes y borradores |
| `LISTADO_DOCUMENTOS` | Archivo y referencias sin PDF |

Cada listado comprueba por separado las acciones `CONSULTAR` y `EXPORTAR`.
Ambas quedan registradas en `cza_auditoria_listados`, junto con el grupo y el
alcance que hicieron efectiva la autorización.

## Ejemplos

Un grupo que consulta el diario solo en la empresa `001`:

```text
RECURSO_GPE     LISTADO_DIARIO
ACCION_GPE      CONSULTAR
ALCANCE_GPE     EMPRESA
CODIGO_EMP_GPE  001
```

Un grupo que consulta y exporta todos los listados en todas las empresas puede
usar dos filas con recurso `LISTADO_*` no admite patrones parciales; se debe
crear una fila por recurso, o emplear `*` si también debe alcanzar al resto de
recursos de la aplicación.
