# Fase 6U — restricción de usuario por documento

Fecha: 28/07/2026. D1.5 y vigésimo primer fascículo de D1 terminados.
Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| Ocho `SqlRestriccionUsuario` | 81 | 40 | -41 |
| Librería `inLibFiltroUsuario` | 221 | 246 | +25 |
| Total productivo de 6U | 302 | 286 | **-16** |

El código productivo del alcance baja un 5,3 %. La primera compilación,
antes de cambios concurrentes ajenos, pasó de las 308.785 líneas de 6T
a 308.769, la misma reducción de 16 líneas. La compilación final incluye
cambios concurrentes en otras unidades y suma 308.880 líneas; por eso el
balance atribuible y reproducible de D1.5 es el de la tabla. Las pruebas
añadidas no se incluyen en estas cifras.

## Implementación

`inLibFiltroUsuario` incorpora `SqlFiltroDocumento`, que recibe el
prefijo de campos del documento y deriva:

- `CODIGO_EMP_<prefijo>`;
- `CODIGO_ALM_<prefijo>`;
- `CODIGO_CAJA_<prefijo>` solo cuando el formulario lo solicita.

La función delega en `SqlFiltroEmpAlmCaja`; por tanto conserva sin
duplicar la activación por parámetro, la exención de administradores,
la omisión de ubicaciones vacías y el `OR ... IS NULL` que evita perder
documentos sin almacén o caja.

Los ocho formularios quedan configurados así:

| Documento | Prefijo | Empresa | Almacén | Caja |
|---|---|---:|---:|---:|
| Pedidos de venta | `PED` | Sí | Sí | No |
| Albaranes de venta | `ALB` | Sí | Sí | No |
| Facturas de venta | `FAC` | Sí | Sí | Sí |
| Inventarios | `INV` | Sí | Sí | No |
| Pedidos de compra | `PEDC` | Sí | Sí | No |
| Albaranes de compra | `ALBC` | Sí | Sí | No |
| Facturas de compra | `FACC` | Sí | Sí | No |
| Devoluciones de compra | `DEVC` | Sí | Sí | No |

No se modifica el punto de inyección de `TfrmMtoGen`, las consultas ni
el comportamiento de las facturas simplificadas que reconstruyen su
propio `WHERE`.

## Pruebas automáticas

Se añade `PruebasFiltroUsuario.pas` con cinco pruebas DUnitX sin BBDD:

1. derivación de empresa y almacén desde un prefijo;
2. inclusión de caja para facturas y tolerancia a columnas `NULL`;
3. ausencia de filtro cuando el parámetro está inactivo;
4. exención de administradores aunque el parámetro esté activo;
5. omisión de almacén y caja cuando faltan en la ubicación del usuario.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 78/78 | 0 | 0 |
| Debug / Win32 | 0 errores | 78/78 | 0 | 0 |
| Release / Win64 | 0 errores | 78/78 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de añadir el módulo de
pruebas y de los cambios concurrentes detectados. La aplicación
principal Release/Win64 se reconstruyó por última vez con Delphi 37:
0 errores, 308.880 líneas y 10,83 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6U no
modifica esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fuentes Pascal del alcance en UTF-8 con BOM y CRLF;
- líneas nuevas Pascal dentro del máximo de 80 columnas;
- ningún `Exit` o `Continue` nuevo;
- `git diff --check` sin errores.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Activar `appRestringirEmpAlmCaja` para un usuario no administrador
   con ubicación `012/GEN/1`.
2. Abrir los ocho documentos y comprobar que solo aparecen cabeceras de
   la empresa 012 y el almacén GEN, incluidas ventas e inventarios.
3. En facturas de venta mayor, confirmar que siguen apareciendo las de
   `CODIGO_CAJA_FAC IS NULL` y que se excluyen otras empresas.
4. Abrir facturas simplificadas y cambiar sus filtros de carga; el
   filtro no debe duplicarse ni desaparecer al reconstruir el `WHERE`.
5. Repetir con usuario administrador y el parámetro activo; debe ver
   todas las empresas, almacenes y cajas.
6. Repetir con un usuario sin almacén o caja por defecto; esa dimensión
   no debe generar condición SQL.

Con este fascículo queda cerrado D1. El siguiente bloque del plan es D2:
partir `TfrmMtoGen`.
