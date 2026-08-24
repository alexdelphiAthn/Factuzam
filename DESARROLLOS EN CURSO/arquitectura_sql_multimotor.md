# Arquitectura SQL multimotor

Estado: política acordada para la transición desde MariaDB y la incorporación de PostgreSQL y SQL Server.

Fecha de referencia: 24/08/2026.

## Objetivo

Permitir que una instalación seleccione MariaDB, PostgreSQL o SQL Server desde la raíz de composición sin modificar formularios, casos de uso ni contratos de negocio. MariaDB conserva el comportamiento de referencia durante la transición, pero no actúa como fallback silencioso para los demás motores.

La solución es híbrida. No se intentará resolver todo el SQL mediante un único generador ni se duplicarán repositorios completos por motor. Cada diferencia se situará en el mecanismo más pequeño que pueda mantener un contrato verificable.

## Decisión arquitectónica

| Necesidad | Mecanismo | Regla |
|---|---|---|
| Lectura reutilizada por varios consumidores y con forma estable | Vista física por motor | La aplicación consulta el mismo contrato lógico `vi_*`; cada motor implementa físicamente la vista. |
| Consulta o comando completo cuya sintaxis cambia | Catálogo SQL por motor | Una clave de operación estable resuelve una variante explícita para el motor activo. |
| Fragmento sintáctico pequeño | `IDialectoSql` | Solo genera o normaliza fragmentos acotados; no contiene consultas de negocio completas. |
| Upsert, identidad, locking, tablas temporales, DDL o metadatos | Adaptador por motor | La diferencia incluye capacidades o semántica, no solo texto SQL. |
| SQL común realmente portable | SQL común probado | Solo permanece común si las pruebas de contrato pasan en todos los motores habilitados. |

La selección del motor y de sus servicios se hace una sola vez en la raíz de composición. Quedan prohibidas las ramas `if Motor = ...` en formularios, dominio, casos de uso y repositorios comunes.

## 1. Vistas físicas por motor para lecturas estables

Las consultas de lectura extensas, repetidas o utilizadas por varios repositorios se publicarán como vistas físicas equivalentes en cada motor.

### Convención de nombres

- Prefijo obligatorio: `vi_`.
- Forma recomendada: `vi_<contexto>_<propósito>` en minúsculas y `snake_case`.
- El nombre lógico no incluye el motor: no se usarán sufijos como `_mysql`, `_pg` o `_sqlserver`.
- El schema físico se obtiene del perfil de conexión y no se codifica en consumidores.

### Contrato de una vista

Todas las implementaciones de una misma vista deben exponer:

1. La misma lista de columnas.
2. Los mismos nombres y el mismo orden de columnas.
3. Tipos lógicos compatibles, incluyendo precisión y escala.
4. La misma nullabilidad observable.
5. La misma semántica para booleanos, importes, fechas, horas y zonas horarias.
6. La misma semántica de joins, filtros, duplicados y agregaciones.
7. Reglas equivalentes de comparación de texto cuando la funcionalidad dependa de mayúsculas, acentos o collation.

Una vista no garantiza orden. Sus scripts no incluirán `ORDER BY` implícito y todo consumidor que dependa del orden deberá expresarlo, con un criterio total y un desempate estable.

Las vistas se consideran contratos de lectura. No se asumirá que son actualizables ni se escribirán mediante ellas salvo que exista un contrato específico y pruebas por motor.

### Cuándo usar una vista

Se prefiere una vista cuando:

- la proyección y sus reglas se reutilizan;
- el resultado tiene una forma estable;
- las diferencias son internas a joins, funciones, agregaciones o conversiones;
- interesa poder optimizar cada motor sin cambiar el Pascal consumidor.

No se usa una vista para ocultar una operación de escritura, una transacción o un protocolo de concurrencia.

## 2. Catálogo SQL por motor

El catálogo conserva una única identidad de operación y variantes explícitas para cada `TMotorBBDD` soportado.

Cada definición debe fijar como contrato común:

- clave estable de operación;
- tipo de sentencia y resultado esperado;
- nombres, dirección y tipos lógicos de parámetros;
- lista, orden, tipos y nullabilidad de campos devueltos;
- requisitos transaccionales y efectos observables.

Reglas de resolución:

- nunca reutilizar implícitamente la variante MariaDB desde PostgreSQL o SQL Server;
- fallar antes de ejecutar si falta la variante del motor activo;
- registrar explícitamente una variante para cada motor aunque el texto sea idéntico;
- separar perfiles personalizados y huellas por motor;
- validar el SQL seleccionado, no solo el SQL histórico de MariaDB;
- no copiar automáticamente una personalización de un motor a otro.

El catálogo es adecuado para `SELECT`, DML y llamadas completas que cambian de sintaxis pero mantienen el mismo contrato. Las capacidades especiales de la sección siguiente no deben degradarse a cadenas dispersas dentro del catálogo.

## 3. `IDialectoSql` para fragmentos

`IDialectoSql` encapsula diferencias sintácticas pequeñas y componibles, por ejemplo:

- delimitación y escape de identificadores;
- paginación y límite de filas;
- expresión de fecha u hora actual;
- suma o diferencia de intervalos;
- concatenación y búsqueda de texto cuando exista equivalencia exacta;
- orden explícito de valores nulos;
- literales tipados necesarios para artefactos SQL, nunca secretos.

Sus métodos deben expresar intención, no palabras de un motor. Por ejemplo, `Paginar`, `DelimitarIdentificador` u `OrdenarNulos`, no `CrearLimitMySQL`.

`IDialectoSql` no debe:

- generar una consulta de negocio completa;
- consultar catálogos del servidor;
- decidir transacciones o aislamiento;
- implementar upsert, identidad o locking;
- traducir texto SQL arbitrario entre dialectos.

## 4. Adaptadores por motor

Las operaciones siguientes requieren adaptadores porque su equivalencia depende de capacidades, estado de sesión o concurrencia.

| Capacidad | Responsabilidad del adaptador |
|---|---|
| Upsert | Resolver conflicto, clave objetivo, valores devueltos y comportamiento concurrente. |
| Identidad y secuencias | Insertar valores explícitos cuando proceda, recuperar la identidad generada y reconciliar el siguiente valor. |
| Locks | Traducir la intención de bloqueo y demostrar aislamiento, espera, timeout y deadlock equivalentes. |
| Tablas temporales | Gestionar creación, nombre, alcance de sesión/transacción, índices y limpieza. |
| DDL | Crear o alterar objetos con tipos, defaults, collations, comentarios, constraints e identidades propios del motor. |
| Metadatos | Separar catálogo/base/schema y leer objetos mediante `information_schema`, `pg_catalog` o `sys.*` según corresponda. |
| Rutinas y triggers | Crear, invocar y eliminar con firma, lenguaje, batches y tabla propietaria correctos. |
| Backup y restauración | Etiquetar el dialecto del artefacto, usar prólogo/parser propios y rechazar restauraciones cruzadas no convertidas. |

Los adaptadores comparten interfaces de intención y resultados, pero no tienen obligación de compartir el SQL interno. No se traducirán automáticamente cuerpos de procedimientos, triggers o vistas obtenidos de otro motor.

## 5. Scripts por motor

Los objetos físicos se mantienen en scripts separados por motor y asociados a una misma versión lógica de esquema.

Todo script debe ser:

- idempotente o tener una precondición idempotente verificable;
- repetible sobre una base desechable y sobre una base ya actualizada;
- explícito sobre catálogo, schema, ownership, permisos, encoding y collation;
- compatible con las reglas transaccionales del motor;
- libre de credenciales, rutas privadas y datos de producción;
- seguro ante ejecución parcial, con rollback o procedimiento de recuperación documentado;
- auditable mediante una versión, descripción y resultado de validación.

Las operaciones que un motor prohíba dentro de una transacción, como determinados pasos administrativos, se separarán del bloque transaccional. Un script idempotente no debe ocultar una incompatibilidad: si un objeto existente tiene un contrato distinto, debe fallar con diagnóstico o migrarlo de forma explícita.

Para cada vista `vi_*`, los tres scripts deben crear el mismo contrato aunque utilicen funciones, casts o catálogos diferentes.

## 6. Pruebas de contrato

### Vistas

- comprobar nombre, orden, tipo lógico y nullabilidad de todas las columnas;
- ejecutar el mismo conjunto de datos límite en los tres motores;
- verificar duplicados, `NULL`, Unicode, acentos, importes, precisión temporal y zonas horarias;
- comprobar que los consumidores añaden un `ORDER BY` total cuando lo necesitan;
- comparar resultados normalizados, no planes de ejecución ni representaciones internas.

### Catálogo

- resolver cada clave para cada motor habilitado;
- demostrar que una variante ausente falla cerrada antes de llegar a UniDAC;
- validar parámetros y campos contra el mismo contrato;
- demostrar que perfiles y fallback nunca cruzan motores;
- probar CTE, llamadas y sentencias con la gramática del motor correspondiente.

### Dialecto y adaptadores

- probar identificadores reservados, mayúsculas y caracteres delimitadores;
- probar paginación con desempate estable y orden de `NULL`;
- probar upsert bajo concurrencia;
- probar identidad y secuencias después de importar valores explícitos;
- probar locks, timeout, deadlock, rollback y aislamiento observable;
- probar ciclo de vida y limpieza de tablas temporales;
- crear, validar y eliminar DDL y metadatos en una base desechable;
- generar y restaurar backups del mismo motor y rechazar artefactos de otro dialecto.

### Scripts

- ejecutar cada migración dos veces;
- validar el contrato de todas las vistas tras cada ejecución;
- conciliar recuentos y totales funcionales relevantes;
- ensayar fallo intermedio y recuperación;
- conservar evidencia por motor y versión.

## 7. Secuencia de migración

1. Clasificar cada SQL inventariado como vista, catálogo, fragmento de dialecto, adaptador o SQL común probado.
2. Hacer que catálogo y composición sean conscientes del motor y fallen cerrados.
3. Migrar primero lecturas de alto uso a vistas `vi_*` con pruebas de contrato.
4. Extraer upsert, identidad, locks, temporales, DDL y metadatos a adaptadores.
5. Sustituir fragmentos residuales por `IDialectoSql`.
6. Añadir scripts idempotentes por motor y ejecutarlos en CI contra bases desechables.
7. Autorizar un motor únicamente cuando sus contratos, migración, backup y rollback estén probados.

## 8. Reglas de cumplimiento

- No introducir provider concreto ni selección de motor fuera de infraestructura/composición.
- No introducir SQL específico sin inventario, estrategia y prueba necesaria.
- No aceptar “parece ANSI” como prueba de portabilidad.
- No usar `LIMIT 1`, `TOP 1` o equivalente cuando el resultado dependa de una fila concreta sin `ORDER BY` total.
- No depender del orden por defecto de `NULL`, de la collation del servidor ni de conversiones implícitas.
- No concatenar identificadores o valores sin validación y parametrización adecuadas.
- No restaurar un script de un motor en otro sin un proceso de conversión explícito.

## Criterio de terminado por operación

Una operación se considera multimotor cuando su mecanismo está clasificado, no contiene fallback cruzado, mantiene el mismo contrato observable, dispone de variante o adaptador para cada motor declarado y sus pruebas pasan en MariaDB, PostgreSQL y SQL Server. Un motor todavía no habilitado puede mantener la operación como pendiente, pero nunca resolverla con SQL de otro motor.
