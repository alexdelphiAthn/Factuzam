# Resultado de la fase SQL-0

Fecha de cierre de implementación: 30/07/2026.

## Estado

La implementación de SQL-0 está terminada. No modifica el esquema de la
BBDD ni `factuzam_original.sql`.

La recompilación final de todas las configuraciones está aplazada por
petición expresa del usuario hasta que terminen las demás tareas
concurrentes. Antes de esa pausa se compiló el proyecto de pruebas Win64
Debug y se ejecutó la batería: las 15 pruebas del catálogo SQL pasaron.
El conjunto completo obtuvo 237 pruebas correctas de 238; el único fallo
fue el caso previo y ajeno
`PruebasGestorPerfilesMto.Carga_ExponeValoresYAplicaCaption`.

Actualización de 30/07/2026: la matriz aplazada se completó al cerrar
SQL-1. El resultado vigente está en
`DESARROLLOS EN CURSO/refactorizacion_fase_sql1_resultados.md`.

## Línea base corregida

El analizador distingue SQL con estructura ejecutable y deja de contar
mensajes o listas de verbos del validador.

| Métrica | Medición histórica | Línea base SQL-0 |
|---|---:|---:|
| Unidades con SQL literal | 79 | 77 |
| Construcciones SQL | 528 | 513 |
| `SELECT` | 345 | 341 |
| `INSERT` | 67 | 66 |
| `UPDATE` | 52 | 48 |
| `DELETE` | 40 | 39 |
| `REPLACE` | 1 | 0 |
| `CALL` | 8 | 7 |
| DDL | 15 | 12 |

La medición histórica y la corregida no son una resta exclusivamente del
validador: además de excluir sus falsos positivos, el criterio nuevo exige
la estructura mínima propia de cada verbo. Por ejemplo, un `UPDATE`
necesita `SET`, un `INSERT` necesita `INTO` y una operación DDL necesita
un objeto SQL reconocible.

El límite predeterminado de
`scripts/comprobar_sql_en_dominio.ps1` es exactamente 513 sentencias y 77
unidades. Por tanto, cualquier aumento hace fallar el control. El inventario
completo y ordenado está guardado en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql0.csv`.

Para reproducirlo:

```powershell
.\scripts\comprobar_sql_en_dominio.ps1
.\scripts\comprobar_sql_en_dominio.ps1 -MostrarTodos
.\scripts\comprobar_sql_en_dominio.ps1 `
  -RutaInventario 'DESARROLLOS EN CURSO\inventario_sql_dominio_sql0.csv'
```

## Entregables

### Contrato y políticas

`TDefinicionSql` incluye campos de salida obligatorios y una política
explícita:

- `pesSoloBase`;
- `pesPerfilLecturaConFallback`;
- `pesPerfilEscrituraTransaccional`.

La validación rechaza definiciones incompletas, combinaciones incompatibles
de tipo y política, parámetros distintos y lecturas que no conserven sus
campos o aliases obligatorios.

### Registro central

`TRegistroDefinicionesSql` posee sus datos y no utiliza variables globales
ni autorregistro en `initialization`. Valida cada definición al añadirla y
rechaza claves duplicadas sin distinguir mayúsculas.

`CrearRegistroDefinicionesSqlAplicacion` es el único punto de composición.
Actualmente registra las dos operaciones del piloto:

- `SQL__RepositorioComprasSesiones__ObtenerSiguienteLinea`;
- `SQL__RepositorioComprasSesiones__ConsultarCantidadesLinea`.

El formulario solicita el registro completo y ya no conoce esa lista.

### Ejecución y fallback

`EjecutarLecturaSqlConFallback` encapsula el comportamiento:

1. resuelve el perfil si el catálogo está activo;
2. usa el SQL base si la resolución falla o descarta el perfil;
3. si falla la ejecución de un SQL de perfil, registra la causa;
4. reintenta exactamente una vez con el SQL base;
5. propaga el error si también falla el SQL base.

El mecanismo recibe un procedimiento ejecutor, por lo que se prueba sin
UniDAC y sin una BBDD real. `TRegistroIncidenciasSql` conserva la última
causa conocida por clave durante su ciclo de vida explícito.

### Administración

La administración puede publicar, revisar y exportar el registro completo.
La revisión informa de SQL base y de perfil, versión, política, huellas,
estado de validación y última causa de fallback.

La exportación crea un `.base.sql` por operación, un `.perfil.sql` cuando
existe una fila y el índice `catalogo_sql.txt` con todos los metadatos.
Las operaciones `pesSoloBase` se revisan y exportan, pero no se publican en
`SQL_REPOSITORIOS`.

## Pruebas añadidas

La batería cubre:

- clave duplicada;
- definición inválida;
- política de solo base;
- lectura con perfil y fallback;
- escritura transaccional;
- registro completo del piloto;
- fallback sin BBDD real;
- propagación del fallo del SQL base;
- contenido de la revisión;
- exportación de base, perfil e índice.

## Validación pendiente

Los controles que no requieren compilación han quedado ejecutados:

- analizador con el límite predeterminado: correcto;
- prueba del techo monotónico con límite 512: falla como corresponde;
- inventario guardado: 77 filas y suma 513;
- XML de ambos proyectos: válido y sin referencias duplicadas;
- espacios finales y `git diff --check` en los archivos SQL-0: correctos.

El control general de capas sigue informando de dos dependencias previas y
ajenas a SQL-0:

- `inLibCajaOpeComposicion -> inMtoCajaImpresorVenta`;
- `inLibCajaOpeComposicion -> inMtoCajaGrabadorVenta`.

Cuando el usuario autorice volver a compilar:

1. compilar `fzam.dproj` en Win32/Win64 y Debug/Release;
2. compilar `tests/FactuzamTests.dproj` en las mismas configuraciones;
3. ejecutar al menos las baterías Win32 y Win64;
4. repetir el analizador y `git diff --check`.
