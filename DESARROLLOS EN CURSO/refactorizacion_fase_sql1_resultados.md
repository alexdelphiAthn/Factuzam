# Resultado de la fase SQL-1

Fecha de cierre: 30/07/2026.

## Estado

SQL-1 está terminada. No modifica el esquema de la BBDD ni
`factuzam_original.sql`.

Los tres contratos de repositorio existentes utilizan ya el mismo catálogo
SQL, con SQL base incluido en el ejecutable y fallback seguro para
lecturas:

- `IRepositorioComprasSesiones`;
- `IRepositorioFacturas`;
- `IRepositorioConsultasCaja`.

El registro central contiene 16 definiciones. Catorce son lecturas
publicables y dos son escrituras de Facturas que permanecen
`pesSoloBase`.

## Implementaciones extraídas

La implementación de Facturas vive ahora en
`src/DataModules/UniDataFacturasRepositorio.pas`. La implementación de
Caja vive en
`src/Caja/DataModules/UniDataCajaConsultasRepositorio.pas`.

Las unidades anteriores:

- `src/Lib/inLibFacturasRepositorio.pas`;
- `src/Caja/Lib/inLibCajaConsultasRepositorio.pas`;

son fachadas de compatibilidad mediante aliases. No contienen SQL ni
lógica nueva.

### RepositorioFacturas

Admite perfil y fallback en cinco lecturas:

- `ExisteSerieOtraEmpresa`;
- `EsPaisUE`;
- `ObtenerOperacionFiscal`;
- `UltimaFechaSerie`;
- `HayHuecoNumeracion`.

`GuardarCliente` y `GuardarEmpresa` son procedimientos con efectos. Se
registran para revisión y exportación, pero su política `pesSoloBase`
impide publicarlos o sustituirlos desde perfiles.

### RepositorioConsultasCaja

Admite perfil y fallback en siete lecturas:

- `ConsultarStock`;
- `ConsultarClientes`;
- `ConsultarEmpleados`;
- `BuscarEmpleado`;
- `ObtenerCliente`;
- `ConsultarCabeceraFactura`;
- `ConsultarLineasFactura`.

`ConsultarStock` es un `CALL` que devuelve un dataset. La validación
admite expresamente este caso sin tratarlo como una escritura.

`BuscarEmpleado` utiliza siempre el parámetro estructural `:TOKEN`. El
valor es `%texto%` o `%` cuando el texto está vacío. Esta normalización
conserva el comportamiento anterior y permite que el contrato de
parámetros sea estable.

## Composición y activación

`UniDataCatalogoSqlAplicacion` es el punto único de composición,
publicación y carga. Las pantallas de Compras, Facturas y Caja le pasan su
interruptor `oGetSQLFromDB`.

Con el interruptor a `False`:

- no se consulta el servicio de perfiles;
- no se publica ni se carga `SQL_REPOSITORIOS`;
- todos los repositorios usan directamente el SQL base.

Con el interruptor a `True`, se publica cualquier lectura ausente sin
sobrescribir filas y se carga el catálogo compartido. Un fallo de
publicación o carga crea igualmente el repositorio en modo base.

## Validación y fallback

La validación estática comprueba tipo, parámetros, campos de salida,
sentencias múltiples y verbos peligrosos. Para lecturas acepta `SELECT` y
procedimientos `CALL` que devuelvan dataset.

`UniDataCatalogoSqlValidacion` comprueba además los campos reales después
de abrir el dataset. Por tanto, una consulta que es válida como texto pero
no devuelve un alias obligatorio también provoca:

1. registro de la incidencia;
2. descarte del resultado personalizado;
3. un único reintento con el SQL base.

Si falla también el SQL base, la excepción se propaga.

## Reducción de SQL en dominio

| Métrica | SQL-0 | SQL-1 | Variación |
|---|---:|---:|---:|
| Unidades con SQL literal | 77 | 75 | -2 |
| Construcciones SQL | 513 | 499 | -14 |
| `SELECT` | 341 | 330 | -11 |
| `INSERT` | 66 | 66 | 0 |
| `UPDATE` | 48 | 48 | 0 |
| `DELETE` | 39 | 39 | 0 |
| `REPLACE` | 0 | 0 | 0 |
| `CALL` | 7 | 4 | -3 |
| DDL | 12 | 12 | 0 |

El nuevo techo predeterminado de
`scripts/comprobar_sql_en_dominio.ps1` es 499 construcciones y 75
unidades. El inventario reproducible está en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql1.csv`.

## Pruebas

SQL-1 añade siete casos que cubren:

- las definiciones y políticas de Facturas;
- las definiciones y políticas de Caja;
- perfil de Facturas sin un campo obligatorio;
- alias con espacios y acentos incorrectos en Caja;
- `CALL` de lectura válido;
- fallback cuando el dataset abierto carece de campos;
- composición desactivada sin servicio de perfiles.

El proyecto de pruebas compila en:

- Win32 Debug;
- Win32 Release;
- Win64 Debug;
- Win64 Release.

Las ejecuciones Debug de ambas arquitecturas encuentran 255 pruebas:
254 pasan y una falla. El único fallo es previo y ajeno a SQL-1:
`PruebasGestorPerfilesMto.Carga_ExponeValoresYAplicaCaption`.
Los siete casos nuevos pasan.

## Compilación de la aplicación

`fzam.dproj` compila en las cuatro combinaciones Win32/Win64 y
Debug/Release. La validación utiliza carpetas aisladas bajo
`build/validacion_sql1`, sin sustituir el ejecutable habitual.

Las compilaciones Release detectaron además solapes de las tareas
concurrentes: referencias de proyecto regeneradas y comprobaciones
`Assigned` sobre accesores que ahora son funciones. Se corrigieron los
puntos concretos y se volvió a compilar la matriz.

## Siguiente fase

SQL-2 debe comenzar por unidades exclusivamente de lectura. El orden
recomendado es:

1. resolución, atributos y validación de artículos;
2. consultas de arqueo y tickets;
3. lecturas pequeñas de Facturas y exportaciones;
4. consultas transversales de una sola responsabilidad.

Las materializaciones y escrituras de negocio continúan fuera de alcance
hasta disponer de límites transaccionales y pruebas de rollback.
