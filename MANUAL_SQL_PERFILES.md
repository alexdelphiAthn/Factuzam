# Manual de administración del SQL por perfiles

## 1. Objetivo

El catálogo SQL permite corregir determinadas consultas sin recompilar ni
sustituir `fzam.exe`.

El dominio no accede a los perfiles ni conoce el texto SQL. Cada operación
llama a un repositorio mediante una interfaz. La implementación UniDAC del
repositorio decide si utiliza:

1. El SQL base incluido y probado con el ejecutable.
2. Una personalización activa guardada en `fza_usuarios_perfiles`.

El piloto está aplicado a dos lecturas de sesiones de compra. El patrón se
extenderá por fascículos al resto de repositorios.

## 2. Componentes

| Unidad | Responsabilidad |
|---|---|
| `inLibCatalogoSqlIntf` | Contratos y metadatos estables del catálogo |
| `inLibCatalogoSqlValidacion` | Valida tipo, parámetros, DDL y sentencias múltiples |
| `inLibCatalogoSqlPerfiles` | Resuelve SQL base o SQL de perfil |
| `inLibCatalogoSqlAdmin` | Publica faltantes, revisa estados y exporta `.sql` |
| `inLibComprasSesionesIntf` | Contrato del repositorio de sesiones |
| `UniDataComprasSesionesRepositorio` | Implementación UniDAC y fallback |

## 3. Cómo se identifica una consulta

Un `inLib*` no tiene una clave de perfil propia. La clave solo se consulta
cuando la pantalla tiene `oGetSQLFromDB=True`. Si está a `False`, no se
lee ninguna `KEY_USUPER` y el repositorio utiliza directamente su SQL base.

Las consultas del repositorio de sesiones usan:

```text
KEY_USUPER = SQL_REPOSITORIOS
```

Cada operación tiene una `SUBKEY_USUPER` estable:

```text
SQL__RepositorioComprasSesiones__ObtenerSiguienteLinea
SQL__RepositorioComprasSesiones__ConsultarCantidadesLinea
```

La subclave identifica `Repositorio + Operación`, no el nombre físico de
la antigua unidad `inLib*`. Así se puede reorganizar el código sin tener
que renombrar las filas de configuración.

`SQL_REPOSITORIOS` es un catálogo compartido. Varias pantallas pueden
activar `oGetSQLFromDB` y consumir la misma operación sin duplicar el SQL
bajo la clave de cada formulario. Cada pantalla conserva su propio
interruptor: activar una no activa las demás.

Una modificación del catálogo sí afecta a todas las pantallas activadas
que llamen a esa operación. Antes de publicarla hay que repasar todos los
consumidores del método del repositorio, no solo la pantalla desde la que
se detectó la incidencia.

| Decisión | `KEY_USUPER` | `SUBKEY_USUPER` | Alcance |
|---|---|---|---|
| Activar perfiles SQL | `frmMtoXxx` | `oGetSQLFromDB` | Solo ese formulario |
| Definir el SQL | `SQL_REPOSITORIOS` | `SQL__Repositorio__Operacion` | Todos los consumidores activados |

El contenido de la fila es:

| Columna | Uso |
|---|---|
| `USUARIO_GRUPO_USUPER` | Debe ser `Todos` para SQL de negocio |
| `KEY_USUPER` | Catálogo compartido `SQL_REPOSITORIOS` |
| `SUBKEY_USUPER` | Clave estable de la operación |
| `VALUE_USUPER` | Estado y metadatos; empieza por `S` o `N` |
| `VALUE_TEXT_USUPER` | Texto SQL completo |
| `INSTANTE_MODIF` / `USUARIO_MODIF` | Auditoría del cambio |

Ejemplo de valor activo:

```text
S;V=1;BASE=huella-del-sql-base
```

El catálogo solo considera activa una entrada cuyo `VALUE_USUPER` empieza
por `S`. Para desactivarla se cambia la primera letra a `N`.

## 4. Activación

El interruptor continúa siendo `oGetSQLFromDB`. Esta propiedad sí vive en
el perfil de cada formulario, por ejemplo:

```text
KEY_USUPER = frmMtoComprasSesiones
SUBKEY_USUPER = oGetSQLFromDB
VALUE_USUPER = True
```

1. En el perfil del formulario `frmMtoComprasSesiones`, establecer
   `oGetSQLFromDB=True`.
2. Cerrar y volver a abrir la pantalla.
3. Al crear el data module, Factuzam carga `SQL_REPOSITORIOS` y publica
   automáticamente cualquier consulta base que todavía falte.
4. Factuzam vuelve a cargar el catálogo compartido y las consultas recién
   publicadas quedan disponibles en esa misma apertura.

Si `oGetSQLFromDB=False`, si no existe la fila o si está desactivada, se usa
siempre el SQL base. Desactivar el interruptor de un formulario no cambia
el comportamiento de los demás formularios.

Si falla la publicación o la carga de `SQL_REPOSITORIOS`, la apertura no
queda bloqueada: se registra el error y se crea el repositorio con SQL base.

Para publicar el piloto anticipadamente también puede ejecutarse:

```text
DESARROLLOS EN CURSO/perfiles_sql_compras_sesiones.sql
```

El script es idempotente y no sobrescribe filas existentes.

## 5. Modificar una consulta

Procedimiento recomendado:

1. Hacer copia de `VALUE_TEXT_USUPER` y de `VALUE_USUPER`.
2. Mantener `USUARIO_GRUPO_USUPER='Todos'`.
3. Editar únicamente `VALUE_TEXT_USUPER`.
4. Conservar exactamente los parámetros y aliases de salida documentados
   en la tabla siguiente.
5. Incrementar la versión de `VALUE_USUPER`.
6. Cerrar y volver a abrir la pantalla para recargar el perfil.
7. Ejecutar el flujo afectado y revisar el log.

| Operación | Parámetros obligatorios | Campos de salida |
|---|---|---|
| `ObtenerSiguienteLinea` | `:s`, `:n`, `:l` | `SIGUIENTE` |
| `ConsultarCantidadesLinea` | `:s`, `:n`, `:l` | `ID_AV_PIVOT_SESCEL`, `TOTAL` |

Los valores externos siguen asignándose con `ParamByName`. No deben
reemplazarse los parámetros por concatenaciones.

## 6. Validación y fallback

Antes de usar una personalización, el catálogo comprueba:

- que no esté vacía;
- que sea del tipo esperado, por ejemplo `SELECT`;
- que contenga exactamente los parámetros declarados;
- que no contenga varias sentencias;
- que no incluya `DROP`, `ALTER` ni `TRUNCATE`.

Si falla esta validación:

1. Se descarta la personalización.
2. Se registra la clave y el motivo.
3. Se ejecuta el SQL base.

Si la validación es correcta pero la consulta falla al abrirse o no devuelve
los campos esperados:

1. Se registra la excepción y la clave.
2. Se repite la lectura con el SQL base.
3. Si también falla el SQL base, la excepción se propaga normalmente.

El fallback automático se aplica inicialmente a lecturas. Una futura
operación de escritura solo podrá habilitarlo si el intento personalizado
está protegido por una transacción y se hace `Rollback` antes de repetir.
Esto evita duplicar escrituras parcialmente realizadas.

## 7. Volver inmediatamente al SQL base

Hay tres opciones, de menor a mayor alcance:

1. Cambiar `VALUE_USUPER` de la operación para que empiece por `N`.
2. Eliminar únicamente la fila personalizada.
3. Establecer `oGetSQLFromDB=False` para desactivar todo el SQL de perfiles
   de esa pantalla.

No es necesario modificar ni desplegar el ejecutable.

## 8. Revisión y exportación

`TAdministradorSqlPerfiles` ofrece tres operaciones:

- `PublicarFaltantes`: crea las filas ausentes sin sobrescribir cambios.
- `Revisar`: compara huellas y clasifica cada consulta.
- `Exportar`: genera el SQL base de referencia en un `.sql` por operación
  y un índice
  `catalogo_sql.txt`.

Los estados de revisión son:

```text
epsFalta
epsDesactivado
epsBase
epsPersonalizado
epsInvalido
```

La exportación debe dirigirse a una carpeta de trabajo, nunca a la carpeta
del ejecutable en producción. Sirve para revisión, control de cambios y
comparación entre instalaciones.

Para revisar el catálogo aplicado en una instalación:

```sql
SELECT SUBKEY_USUPER, VALUE_USUPER, VALUE_TEXT_USUPER,
       INSTANTE_MODIF, USUARIO_MODIF
  FROM fza_usuarios_perfiles
 WHERE USUARIO_GRUPO_USUPER = 'Todos'
   AND KEY_USUPER = 'SQL_REPOSITORIOS'
 ORDER BY SUBKEY_USUPER;
```

La consulta muestra el texto efectivo almacenado. Los `.sql` exportados
permiten compararlo con la referencia incluida en la versión del ejecutable.

## 9. Añadir una operación nueva

1. Declarar el método de negocio en `IRepositorioXxx`.
2. Implementarlo en la capa UniDAC.
3. Crear su `TDefinicionSql` indicando:
   - repositorio;
   - operación;
   - SQL base;
   - lista exacta de parámetros;
   - tipo de sentencia;
   - versión.
4. Añadir la definición a `DefinicionesSql`.
5. Añadir pruebas del catálogo y del dominio con repositorio falso.
6. Compilar Win32 y Win64.
7. Publicar la nueva definición mediante `PublicarFaltantes`.

Nunca debe exponerse un método genérico como
`Ejecutar(const ASql: string)` al dominio. El contrato expresa operaciones
de negocio y el texto SQL queda en la implementación de persistencia.

## 10. Diagnóstico rápido

### La personalización no se aplica

- Comprobar `oGetSQLFromDB=True`.
- Comprobar `KEY_USUPER` y `SUBKEY_USUPER`.
- Comprobar que `VALUE_USUPER` empieza por `S`.
- Cerrar y volver a abrir la pantalla.

### Aparece “parámetros esperados/encontrados”

Comparar los nombres precedidos por `:` con la tabla del apartado 5. Los
nombres no distinguen mayúsculas, pero no pueden faltar ni sobrar.

### La consulta personalizada falla y el usuario no ve el error

Es el comportamiento previsto si el SQL base funciona: el flujo continúa
con el fallback. La incidencia queda registrada con el texto
`SQL de perfil fallido` o `SQL de perfil descartado`.

### También falla el SQL base

El problema ya no es la personalización. La excepción se propaga y debe
revisarse como un error normal de conexión, esquema o compatibilidad.
