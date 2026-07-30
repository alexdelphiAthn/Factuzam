# Resultado de la fase SQL-2.1

Fecha de cierre: 30/07/2026.

## Estado

SQL-2.1 está terminada. No modifica el esquema de la BBDD ni
`factuzam_original.sql`.

Las diez lecturas que antes construía `inLibArticulosResolver` están
detrás del contrato `IArticulosResolver`. El contrato no conoce UniDAC,
tablas ni nombres de columnas. La implementación concreta vive en
`src/DataModules/UniDataArticulosResolverRepositorio.pas`.

El registro central contiene ahora 26 definiciones:

- 24 lecturas personalizables con fallback al SQL base;
- dos escrituras de Facturas que permanecen `pesSoloBase`.

## Operaciones extraídas

`RepositorioArticulosResolver` publica estas diez operaciones:

1. `DescuentoTarifaVigente`;
2. `ContarSkusActivos`;
3. `ResolverPrecio`;
4. `ObtenerCosteSku`;
5. `ObtenerCosteProveedor`;
6. `ObtenerCostePrincipal`;
7. `ResolverPmpAlmacen`;
8. `ResolverPmpTotal`;
9. `ObtenerDatosArticulo`;
10. `ListarSkus`.

Cada definición declara su tipo, parámetros obligatorios, campos de
salida y SQL base. Un perfil solo se utiliza si cumple ese contrato.

`ListarSkus` era la única consulta cuya estructura se componía en tiempo
de ejecución. Se ha normalizado con el parámetro `:incluir`:

- `S` incluye SKU inactivos;
- `N` limita el resultado a SKU activos.

La consulta mantiene así una estructura estable para poder publicarse,
validarse y corregirse desde perfiles.

## Separación por contrato

`src/Lib/inLibArticulosResolverIntf.pas` contiene:

- los tipos de dominio;
- `IArticulosResolver`;
- la función pura `DescuentoEnVentana`.

`src/Lib/inLibArticulosResolver.pas` queda como fachada de
compatibilidad de tipos. No contiene SQL ni crea la implementación
concreta.

Los formularios y servicios consumidores dependen de
`IArticulosResolver`. `TfrmBase` actúa como raíz de composición y ofrece
`CrearResolverArticulos`, de modo que el dominio no decide qué
repositorio ni qué catálogo debe utilizar.

Facturas recibe también el resolver mediante `TServiciosFactura`. La
composición comparte el mismo catálogo y el mismo colector de
incidencias que el resto de sus repositorios.

## Activación por pantalla

`TfrmBase` obtiene de forma perezosa el valor:

```text
KEY_USUPER=<nombre del formulario>
SUBKEY_USUPER=oGetSQLFromDB
```

Con `oGetSQLFromDB=False` no consulta ni publica
`SQL_REPOSITORIOS`; el resolver ejecuta directamente el SQL base
incluido en el ejecutable.

Con `oGetSQLFromDB=True` carga el catálogo compartido. La operación se
busca mediante una clave independiente de la pantalla:

```text
KEY_USUPER=SQL_REPOSITORIOS
SUBKEY_USUPER=SQL__RepositorioArticulosResolver__<Operacion>
```

Por tanto, una misma definición sirve para todos los formularios que
consuman esa operación. El interruptor sigue siendo individual para cada
pantalla y decide si esa pantalla aplica o ignora el catálogo.

## Fallback

Las diez operaciones son lecturas y admiten un único reintento seguro con
el SQL base cuando:

- falta la definición de perfil;
- la definición no supera la validación estática;
- falla la ejecución del SQL personalizado;
- el dataset no contiene todos los campos de salida obligatorios.

La incidencia queda registrada antes del reintento. Si falla también el
SQL base, la excepción se propaga.

`DescuentoTarifaVigente` conserva además la compatibilidad anterior con
instalaciones cuyo esquema todavía no contenga las columnas de vigencia
del descuento.

## Consumidores migrados

Se han migrado los formularios de albaranes, pedidos, facturas,
devoluciones, caja, stock, búsqueda y listado de ventas. Las funciones de
documentos de trabajo reciben ahora el contrato por inyección en vez de
construir el resolver concreto.

No queda ningún consumidor que instancie el antiguo
`TArticulosResolver`.

## Reducción de SQL en dominio

| Métrica | SQL-1 | SQL-2.1 | Variación |
|---|---:|---:|---:|
| Unidades con SQL literal | 75 | 74 | -1 |
| Construcciones SQL | 499 | 489 | -10 |
| `SELECT` | 330 | 320 | -10 |
| `INSERT` | 66 | 66 | 0 |
| `UPDATE` | 48 | 48 | 0 |
| `DELETE` | 39 | 39 | 0 |
| `REPLACE` | 0 | 0 | 0 |
| `CALL` | 4 | 4 | 0 |
| DDL | 12 | 12 | 0 |

El techo predeterminado de
`scripts/comprobar_sql_en_dominio.ps1` queda en 489 construcciones y 74
unidades. El inventario reproducible está en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql2_1.csv`.

## Pruebas

SQL-2.1 añade cinco pruebas para cubrir:

- las diez definiciones de lectura y fallback;
- el parámetro estructural estable de `ListarSkus`;
- el fallback por ausencia de campos obligatorios;
- el fallback por error de ejecución sin depender de una BBDD real;
- los límites de vigencia de descuento mediante una función pura.

Las ejecuciones Debug de Win32 y Win64 encuentran 260 pruebas y pasan
las 260.

El proyecto de pruebas y la aplicación compilan en:

- Win32 Debug;
- Win32 Release;
- Win64 Debug;
- Win64 Release.

La validación utiliza salidas aisladas bajo
`build/validacion_sql21`, sin sustituir el ejecutable habitual.

## Comprobaciones complementarias

- el comprobador de dependencias de capas no detecta infracciones;
- los proyectos Delphi no contienen referencias duplicadas;
- las nuevas unidades respetan el máximo de 80 columnas;
- el analizador rechaza un techo inferior a 489;
- no se ha realizado ningún cambio de esquema.

## Siguiente fase

SQL-2.2 debe continuar con atributos y validaciones de artículo,
agrupando las operaciones por agregado y manteniendo contratos sin
dependencias de UniDAC. Después se abordarán las consultas de arqueo y
tickets.

Las materializaciones y escrituras de negocio continúan fuera de alcance
hasta definir sus límites transaccionales y pruebas de rollback.
