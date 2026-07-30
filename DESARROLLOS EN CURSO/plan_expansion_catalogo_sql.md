# Plan de expansión del catálogo SQL y contratos de repositorio

Fecha de referencia: 29/07/2026.

## 1. Objetivo

Extraer progresivamente el SQL de las unidades `inLib*` y situarlo detrás
de contratos de repositorio pequeños. El dominio debe expresar operaciones
de negocio y no conocer UniDAC, nombres de tabla ni detalles del esquema.

Cada operación conservará un SQL base dentro del ejecutable. Las operaciones
autorizadas podrán sustituirlo mediante el catálogo compartido
`SQL_REPOSITORIOS`, sin duplicar la definición por formulario y con vuelta
segura al SQL base cuando corresponda.

Este trabajo no pretende mover cadenas de una unidad a otra sin cambiar la
dirección de dependencias. Una migración solo cuenta como terminada cuando:

- el consumidor depende de una interfaz;
- la implementación UniDAC vive en la capa de persistencia;
- el SQL desaparece de la unidad de dominio original;
- el SQL base, su contrato y su política de ejecución quedan registrados;
- existen pruebas del contrato y del fallback;
- la métrica automática disminuye.

## 2. Punto de partida

La medición del 29/07/2026 detecta:

| Métrica | Valor |
|---|---:|
| Unidades `inLib*` con construcciones SQL | 79 |
| Construcciones SQL detectadas | 528 |
| `SELECT` | 345 |
| `INSERT` | 67 |
| `UPDATE` | 52 |
| `DELETE` | 40 |
| `REPLACE` | 1 |
| `CALL` | 8 |
| DDL detectado | 15 |
| Unidades que solo contienen lecturas | 44 |
| SQL contenido en esas unidades de lectura | 173 |

El recuento es heurístico. Incluye seis falsos positivos de
`inLibCatalogoSqlValidacion`, porque esa unidad contiene los nombres de los
verbos que valida. También mezcla:

- SQL de dominio todavía sin extraer;
- repositorios ya creados pero aún no conectados al catálogo;
- operaciones técnicas de copia, diagnóstico o estructura;
- palabras SQL que no siempre representan una sentencia ejecutada.

SQL-0 ha fijado una línea base corregida de 513 casos en 77 unidades. El
inventario reproducible está en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql0.csv`. Los 528 casos
anteriores se conservan como medición histórica sin depurar.

SQL-1 reduce esa línea a 499 casos en 75 unidades. Su inventario está en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql1.csv` y pasa a ser el
techo monotónico del analizador.

SQL-2.1 extrae las diez lecturas de `inLibArticulosResolver` y reduce el
techo a 489 casos en 74 unidades. El inventario queda en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql2_1.csv`.

SQL-2.2 extrae las catorce lecturas de validación y atributos de artículos.
El techo baja a 475 casos en 72 unidades y el inventario queda en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql2_2.csv`.

SQL-2.3a extrae las seis construcciones de lectura del ticket de
traspasos. Las dos consultas de stock duplicadas convergen en una sola
operación, por lo que el registro incorpora cinco definiciones. El techo
baja a 469 casos en 71 unidades y el inventario queda en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql2_3a.csv`.

SQL-2.3b1 extrae las diez lecturas ejecutadas por el cálculo principal de
arqueo. Nueve admiten perfil y fallback; la comprobación técnica de esquema
permanece `pesSoloBase`. El techo baja a 459 casos en 71 unidades y el
inventario queda en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql2_3b1.csv`.

SQL-2.3b2 extrae los dos resúmenes que quedaban en `inLibArqueo` y las
nueve construcciones literales de `inLibArqueoTicket`. El catálogo incorpora
once lecturas. La contribución directa de la fase es una reducción de 12
casos y dos unidades. El árbol compartido queda en 341 casos y 67 unidades
porque incorpora además una reducción concurrente de 106 casos en Compras.
El inventario queda en
`DESARROLLOS EN CURSO/inventario_sql_dominio_sql2_3b2.csv`.

Los veinte focos mayores suman 354 casos, un 67 % del total. No deben
abordarse primero solo por tamaño: varios contienen materializaciones y
escrituras de alto riesgo.

## 3. Inventario por agregado

La siguiente clasificación no tiene solapamientos y suma las 79 unidades y
los 528 casos detectados.

| Bloque | Unidades | SQL detectado | Tratamiento |
|---|---:|---:|---|
| Plataforma y repositorios existentes | 3 | 20 | Normalizar y corregir métrica |
| Compras | 11 | 188 | Lecturas primero; escrituras transaccionales |
| Artículos, SKU y fotos | 15 | 111 | Separar consulta, stock, SKU y ficheros |
| Caja y tickets | 11 | 69 | Lecturas antes de cierres y arqueos |
| Facturación, ventas e integraciones | 16 | 75 | Separar fiscal, colas y documentos |
| Documentos transversales | 5 | 23 | Numeración y valores compartidos |
| Infraestructura técnica | 18 | 42 | Puertos técnicos o exclusión justificada |
| **Total** | **79** | **528** | |

### 3.1 Plataforma y repositorios existentes

- `inLibCatalogoSqlValidacion` (6, falsos positivos).
- `inLibFacturasRepositorio` (7, contrato existente).
- `inLibCajaConsultasRepositorio` (7, contrato existente).

El piloto `UniDataComprasSesionesRepositorio` ya está fuera de `src/Lib` y
no aparece en la cifra. Tiene dos lecturas catalogadas.

### 3.2 Compras

- `inLibComprasSesionesMaterializar` (61).
- `inLibComprasSesiones` (45).
- `inLibPedidosCompra` (28).
- `inLibGridPivoteCompra` (17).
- `inLibAlbaranesCompraMovimientos` (12).
- `inLibDevolucionesCompraMovimientos` (9).
- `inLibDevolucionesCompraStock` (8).
- `inLibComprasImpuestos` (3).
- `inLibComprasSesionesReglas` (2).
- `inLibBusquedasCompra` (2).
- `inLibValidacionDocumento` (1).

### 3.3 Artículos, SKU y fotos

- `inLibFotos` (20).
- `inLibColumnasSkuModoTallas` (18).
- `inLibGridPivoteVenta` (13).
- `inLibArticulosVariaciones` (11).
- `inLibArticulosResolver` (10).
- `inLibArticulosAtributosLookup` (7).
- `inLibArticulosValidador` (7).
- `inLibAtributosPaleta` (6).
- `inLibGridTallasInline` (5).
- `inLibArticulosCodigosBarras` (4).
- `inLibGridArticulos` (4).
- `inLibArticulosFiltro` (2).
- `inLibInventarioNube` (2).
- `inLibUnidadesMedida` (1).
- `inLibColumnasSkuModoSku` (1).

### 3.4 Caja y tickets

- `inLibArqueo` (14).
- `inLibGenerarTicketBD` (14).
- `inLibTiraCajaTicket` (10).
- `inLibArqueoTicket` (9).
- `inLibArqueoPersistencia` (7).
- `inLibTraspasoTicket` (6).
- `inLibCajaStock` (3).
- `inLibGenerarTicket` (3).
- `inLibFaseCobro` (1).
- `inLibGenerarTicketCaja` (1).
- `inLibCorreoTickets` (1).

### 3.5 Facturación, ventas e integraciones

- `inLibVentasWsJson` (17).
- `inLibVentasWsCola` (12).
- `inLibFacturas` (7).
- `inLibFacturasReapertura` (6).
- `inLibVerifactuNoVerifactuExport` (6).
- `inLibFacturae` (5).
- `inLibFacturasBorrado` (5).
- `inLibSepaRemesasVenta` (3).
- `inLibFacturasMovimientos` (3).
- `inLibFacturasEfectos` (3).
- `inLibFacturasConsolidacion` (2).
- `inLibFormatoDocumento` (2).
- `inLibVentasImpuestos` (1).
- `inLibRectificativas` (1).
- `inLibFacturaPdfBlob` (1).
- `inLibVentasCalendario` (1).

### 3.6 Documentos transversales

- `inLibContadorLineas` (8).
- `inLibDocumentosTrabajo` (6).
- `inLibValoresAutomaticos` (5).
- `inLibImpuestosComun` (3).
- `inLibColumnasDocumento` (1).

### 3.7 Infraestructura técnica

- `inLibPermisosAdmin` (9).
- `inLibBackupWorker` (6).
- `inLibGridColumnChooser` (3).
- `inLibData` (3).
- `inLibDBStructure` (3).
- `inLibGestorGuiasGridMto` (2).
- `inLibDevExp` (2).
- `inLibGestorPerfilesMto` (2).
- `inLibLayoutForm` (2).
- `inLibLicenciaAplicacion` (2).
- `inLibConfigCampos` (1).
- `inLibDatasets` (1).
- `inLibTraducciones` (1).
- `inLibUnitForm` (1).
- `inLibShowMto` (1).
- `inLibPermisosUniDAC` (1).
- `inLibDiag` (1).
- `inLibInformesGuiasCache` (1).

Este último grupo exige una auditoría manual. Las operaciones reales de
persistencia tendrán un puerto técnico; los falsos positivos se corregirán
en el analizador. DDL, restauraciones y cambios de estructura nunca serán
personalizables mediante perfiles.

## 4. Arquitectura objetivo

La dirección de dependencias será:

```text
Formulario o servicio
        |
        | usa IRepositorioXxx
        v
Contrato inLib*Intf
        ^
        |
Implementación UniData*Repositorio
        |
        +--> ICatalogoSql
        |
        +--> UniDAC / MariaDB
```

El formulario decide si habilita personalizaciones con su propio
`oGetSQLFromDB`. La consulta no se guarda bajo la clave del formulario:

```text
KEY_USUPER    = SQL_REPOSITORIOS
SUBKEY_USUPER = SQL__Repositorio__Operacion
```

Varias pantallas pueden consumir la misma operación. Cada pantalla conserva
su interruptor independiente.

### 4.1 Forma de los contratos

Los contratos expresan operaciones de negocio:

```pascal
IRepositorioArticulos = interface
  function ExisteCodigo(const ACodigo: string): Boolean;
  function ObtenerDatosSku(
    const ACodigoSku: string): TDatosSku;
end;
```

No se admiten en contratos de dominio métodos como:

```pascal
Ejecutar(const ASql: string)
AbrirConsulta(const ASql: string): TDataSet
```

Los resultados nuevos serán records, arrays o interfaces de lectura. No
expondrán `TUniQuery`, conexiones ni componentes visuales. Las fachadas
heredadas podrán conservar temporalmente un `TDataSet`, pero tendrán una
tarea explícita de retirada.

### 4.2 Política de ejecución

Antes de ampliar el catálogo se añadirá una política explícita a cada
definición:

```text
pesSoloBase
pesPerfilLecturaConFallback
pesPerfilEscrituraTransaccional
```

| Política | Perfil | Fallback | Uso |
|---|---|---|---|
| `pesSoloBase` | No | No | DDL, copias, restauraciones o riesgo no resuelto |
| `pesPerfilLecturaConFallback` | Sí | Sí | `SELECT` y consultas sin efectos |
| `pesPerfilEscrituraTransaccional` | Sí | Tras `Rollback` | Escritura atómica e idempotente |

Ninguna escritura se marcará como personalizable solo porque el validador
reconozca `INSERT`, `UPDATE` o `DELETE`.

### 4.3 Metadatos mínimos por operación

Cada `TDefinicionSql` tendrá:

- repositorio;
- operación;
- SQL base;
- parámetros exactos;
- tipo de sentencia;
- campos de salida obligatorios;
- versión del contrato;
- política de ejecución.

Los parámetros y aliases forman parte del contrato. Un perfil que añada,
quite o renombre alguno será rechazado antes de ejecutarse.

### 4.4 Registro central

La publicación no puede depender de haber abierto previamente todas las
pantallas. Se creará un registro de definiciones construido en la raíz de
composición:

- cada repositorio aporta sus definiciones;
- el registro comprueba claves duplicadas;
- `TAdministradorSqlPerfiles` publica todas las ausentes;
- la publicación nunca sobrescribe una fila existente;
- la revisión y exportación trabajan sobre el registro completo.

El registro tendrá propietario y ciclo de vida explícitos. No se usará
estado global mutable ni autorregistro mediante `initialization`.

El piloto puede seguir publicando al abrir la pantalla hasta que el registro
central esté operativo. Después, los formularios solo cargarán o ignorarán
el catálogo según su interruptor.

### 4.5 Consumidores sin formulario

Los procesos en segundo plano y servicios no tienen
`oGetSQLFromDB`. Recibirán explícitamente uno de estos catálogos:

- catálogo base, opción predeterminada;
- catálogo de perfiles habilitado por configuración del proceso.

Nunca se supondrá que un proceso debe usar perfiles por el nombre de la
unidad o del data module.

## 5. Fases de ejecución

Cada fase se divide en fascículos pequeños. Un fascículo cubre un contrato
cohesivo, un máximo orientativo de doce sentencias o una única transacción
de negocio. No se mezclan agregados para alcanzar una cifra.

### Fase SQL-0 — endurecer la plataforma

Entregables:

1. Añadir la política de ejecución a `TDefinicionSql`.
2. Añadir y validar los campos de salida obligatorios.
3. Crear el registro central de definiciones sin estado global.
4. Hacer que revisión y exportación incluyan:
   - SQL base;
   - SQL de perfil;
   - versión;
   - huellas;
   - estado de validación;
   - última causa conocida de fallback, si está disponible.
5. Añadir una publicación completa y explícita para administración.
6. Corregir `comprobar_sql_en_dominio.ps1` para:
   - no contar los verbos del validador como SQL;
   - distinguir lecturas, escrituras, `CALL` y DDL;
   - generar inventario completo además del resumen;
   - impedir que el total ajustado aumente.
7. Añadir pruebas de claves duplicadas y de todas las políticas.

Criterio de salida:

- línea base corregida guardada;
- todas las definiciones del piloto registradas;
- ningún formulario necesita conocer la lista global;
- fallback de lectura probado sin BBDD real.

Estado a 30/07/2026: implementación terminada. La línea base corregida,
el detalle de los entregables y la validación ejecutada están documentados
en `DESARROLLOS EN CURSO/refactorizacion_fase_sql0_resultados.md`.

### Fase SQL-1 — normalizar los repositorios existentes

Alcance:

- `IRepositorioComprasSesiones`;
- `IRepositorioFacturas`;
- `IRepositorioConsultasCaja`.

Trabajo:

1. Mantener el piloto de ComprasSesiones como referencia.
2. Añadir `DefinicionesSql` a Facturas y Caja.
3. Inyectar `ICatalogoSql`.
4. Aplicar perfil y fallback solo a sus lecturas.
5. Mantener temporalmente las escrituras de Facturas como `pesSoloBase`.
6. Mover las implementaciones concretas de `src/Lib` a `src/DataModules`
   cuando no rompa consumidores; usar una fachada temporal si es necesario.
7. Eliminar 14 construcciones del recuento de dominio.

Criterio de salida:

- los tres contratos usan el mismo mecanismo;
- ninguna pantalla duplica SQL;
- Facturas y Caja tienen pruebas equivalentes al piloto;
- las fachadas no reciben lógica nueva.

Estado a 30/07/2026: fase terminada. El registro contiene 16 definiciones:
14 lecturas personalizables con fallback y dos escrituras de Facturas
`pesSoloBase`. Las implementaciones concretas se han movido a
`DataModules`; las antiguas unidades `inLib*Repositorio` son fachadas de
compatibilidad sin SQL. La línea base queda en 499 construcciones y 75
unidades. El detalle está en
`DESARROLLOS EN CURSO/refactorizacion_fase_sql1_resultados.md`.

### Fase SQL-2 — unidades exclusivamente de lectura

Alcance inicial: 44 unidades y 173 construcciones detectadas.

Orden interno:

1. consultas de artículos, atributos y SKU;
2. consultas de caja, arqueo y tickets;
3. consultas de facturas y exportaciones;
4. consultas de compras;
5. consultas transversales pequeñas.

Las operaciones se agrupan por agregado, no por nombre de la unidad origen.
Por ejemplo, las consultas de artículo repartidas entre
`inLibArticulosResolver`, `inLibArticulosValidador` y
`inLibArticulosAtributosLookup` deben converger en contratos cohesivos, no
en tres repositorios que repitan tablas y conceptos.

Criterio de salida de cada fascículo:

- SQL base idéntico o equivalencia documentada;
- perfil válido utilizado con `oGetSQLFromDB=True`;
- perfil inválido y excepción de ejecución vuelven al SQL base;
- con `oGetSQLFromDB=False` no se carga `SQL_REPOSITORIOS`;
- parámetros y campos de salida probados;
- métrica reducida y cuatro configuraciones compiladas.

Estado de SQL-2.1 a 30/07/2026: implementación terminada. El contrato
`IArticulosResolver` no expone UniDAC y la implementación concreta vive
en `UniDataArticulosResolverRepositorio`. Sus diez lecturas están
registradas con perfil y fallback. El formulario base compone el catálogo
de forma perezosa usando el interruptor de la pantalla consumidora. El
detalle está en
`DESARROLLOS EN CURSO/refactorizacion_fase_sql2_1_resultados.md`.

Estado de SQL-2.2 a 30/07/2026: implementación terminada. Los contratos
`IArticulosValidador` e `IArticulosAtributosLookup` no exponen UniDAC.
Sus implementaciones concretas registran siete lecturas cada una. Los
formularios inyectan ambos contratos en los modos de SKU, desglose, tallas
y pivote, conservando el interruptor de la pantalla consumidora. El
detalle está en
`DESARROLLOS EN CURSO/refactorizacion_fase_sql2_2_resultados.md`.

Estado de SQL-2.3a a 30/07/2026: implementación terminada.
`IRepositorioTraspasoTicket` abstrae solicitudes, líneas, stock y
reimpresión histórica. `inLibTraspasoTicket` conserva la composición del
ticket, pero ya no conoce UniDAC ni contiene SQL. Sus cinco operaciones
usan el catálogo de la pantalla consumidora y fallback al SQL base. El
detalle está en
`DESARROLLOS EN CURSO/refactorizacion_fase_sql2_3a_resultados.md`.

Estado de SQL-2.3b1 a 30/07/2026: implementación terminada.
`IRepositorioArqueoCaja` abstrae el read model principal del arqueo. La
implementación `UniDataArqueoRepositorio` registra nueve lecturas con
perfil y fallback y una comprobación técnica `pesSoloBase`. El formulario,
el ticket y la reimpresión histórica reciben el repositorio creado por la
pantalla consumidora. El detalle está en
`DESARROLLOS EN CURSO/refactorizacion_fase_sql2_3b1_resultados.md`.

Estado de SQL-2.3b2 a 30/07/2026: implementación terminada.
`IRepositorioArqueoTicket` abstrae cabecera, contadores, devoluciones,
resúmenes y reimpresión histórica. `inLibArqueoTicket` ya no conoce UniDAC
ni contiene SQL. El resumen por sección usa una consulta única con
`:pNIVELES` y la comparten el formulario y el ticket. El detalle está en
`DESARROLLOS EN CURSO/refactorizacion_fase_sql2_3b2_resultados.md`.

SQL-2.3c debe continuar con las diez lecturas de `inLibTiraCajaTicket`.
Las escrituras de cierre y persistencia permanecen fuera de alcance.

### Fase SQL-3 — lecturas dentro de unidades mixtas

Quedan aproximadamente 172 lecturas dentro de unidades que también
escriben. Se extraerán sin mover aún las escrituras.

Prioridad:

1. `inLibComprasSesiones` y
   `inLibComprasSesionesMaterializar`;
2. `inLibPedidosCompra`;
3. `inLibFotos`;
4. `inLibColumnasSkuModoTallas`;
5. `inLibGridPivoteCompra` y `inLibGridPivoteVenta`;
6. movimientos de compra y devolución;
7. colas e integraciones de venta.

La unidad original puede actuar como fachada mientras tenga consumidores.
Una fachada no conserva SQL: delega en el contrato nuevo.

Criterio de salida:

- ninguna lectura nueva se añade al legado;
- las lecturas extraídas pueden probarse con repositorios falsos;
- las escrituras restantes están inventariadas por transacción.

### Fase SQL-4 — escrituras simples y acotadas

Alcance:

- altas, cambios o borrados de una sola responsabilidad;
- operaciones que ya son atómicas;
- escrituras que pueden hacerse idempotentes con una clave natural.

Orden recomendado:

1. colas e indicadores de integración;
2. preferencias y metadatos persistentes;
3. fotos, códigos de barras y atributos aislados;
4. efectos y relaciones de factura simples;
5. contadores que tengan control de concurrencia definido.

Pasos obligatorios:

1. Mantener inicialmente `pesSoloBase`.
2. Encapsular la transacción en la implementación.
3. Probar fallo antes y después de la escritura.
4. Demostrar `Rollback`.
5. Demostrar que repetir no duplica datos.
6. Solo entonces habilitar
   `pesPerfilEscrituraTransaccional`.

Criterio de salida:

- nunca se reintenta una escritura fuera de una transacción;
- el log distingue fallo de perfil, rollback y fallo del SQL base;
- el SQL base sigue siendo el último recurso seguro.

### Fase SQL-5 — transacciones de negocio de alto riesgo

Alcance principal:

- materializar y revertir sesiones de compra;
- crear albaranes desde pedidos;
- movimientos y stock de albaranes y devoluciones;
- reapertura, borrado y consolidación de facturas;
- arqueos y cierres de caja.

Estas operaciones no se convertirán sentencia a sentencia. El contrato
representará el caso de uso atómico y la implementación controlará todas
sus consultas dentro de una unidad de trabajo.

Para cada flujo:

1. documentar tablas leídas y escritas;
2. fijar precondiciones y postcondiciones;
3. identificar la clave de idempotencia;
4. fijar el límite exacto de la transacción;
5. probar fallo en cada punto significativo;
6. comprobar que el rollback restaura el estado;
7. decidir si se permite perfil o permanece para siempre en
   `pesSoloBase`.

Criterio de salida:

- ninguna materialización parcial queda persistida;
- el dominio no recibe una conexión ni controla UniDAC;
- las pruebas de integración están marcadas expresamente;
- el fixture DUnitX ordinario no depende de una BBDD real.

### Fase SQL-6 — `CALL`, DDL e infraestructura

Los ocho `CALL` y quince casos DDL se revisan uno a uno.

Clasificación:

- `CALL` de lectura: contrato y política de lectura;
- `CALL` con efectos: misma política que una escritura transaccional;
- copia, restauración, diagnóstico o cambio de esquema:
  implementación técnica y `pesSoloBase`;
- falso positivo: corrección del analizador;
- SQL de UI o metadata: mover al puerto técnico correspondiente.

No se permitirá desde perfiles:

- `CREATE`;
- `ALTER`;
- `DROP`;
- `TRUNCATE`;
- restauraciones;
- cambios de contraseña o permisos estructurales;
- scripts con varias sentencias.

Criterio de salida:

- cada caso está convertido, marcado como base inmutable o eliminado como
  falso positivo;
- no queda DDL personalizable;
- el analizador no necesita ocultar deuda real.

### Fase SQL-7 — retirada de fachadas y cierre

1. Migrar los últimos consumidores de cada fachada.
2. Eliminar APIs que reciben conexiones o SQL desde dominio.
3. Eliminar unidades de compatibilidad sin consumidores.
4. Publicar el catálogo completo de base.
5. Revisar perfiles personalizados contra las huellas actuales.
6. Exportar base y perfiles para auditoría.
7. Ejecutar compilaciones y pruebas finales.
8. Actualizar `PLAN_SOLID.md`, libros de estilo e issues.

Criterio de salida global:

- cero SQL de negocio real dentro de `src/Lib` y `src/Caja/Lib`;
- todo acceso de negocio pasa por contratos;
- toda definición tiene clave única y política explícita;
- ninguna escritura tiene fallback inseguro;
- el catálogo completo puede publicarse y revisarse sin abrir pantallas;
- los formularios solo coordinan y el dominio se prueba sin BBDD.

## 6. Contratos objetivo por bloque

Los nombres finales se confirmarán al inventariar operaciones. No se creará
un contrato por cada unidad histórica.

| Bloque | Contratos candidatos |
|---|---|
| Compras | `IRepositorioComprasSesiones`, `IRepositorioPedidosCompra`, `IRepositorioDocumentosCompra`, `IRepositorioMovimientosCompra` |
| Artículos | `IRepositorioArticulos`, `IRepositorioSku`, `IRepositorioFotos`, `IRepositorioAtributos` |
| Caja | `IRepositorioConsultasCaja`, `IRepositorioArqueos`, `IRepositorioTicketsCaja` |
| Facturación | `IRepositorioFacturas`, `IRepositorioEfectosVenta`, `IRepositorioDocumentosFiscales` |
| Integraciones | `IRepositorioColaVentas`, `IRepositorioVerifactuExportacion` |
| Transversal | `IRepositorioNumeracion`, `IRepositorioValoresAutomaticos`, `IRepositorioPermisos` |
| Técnico | `IPersistenciaPerfiles`, `IMantenimientoBbdd`, `ICopiasSeguridad` |

Si un contrato crece demasiado, se divide por consumidor o caso de uso,
siguiendo ISP. No se fusionan operaciones solo porque consulten la misma
tabla.

## 7. Plantilla obligatoria de un fascículo

### 7.1 Inventario

- unidad y métodos afectados;
- consumidores reales;
- tablas;
- tipo de cada sentencia;
- parámetros;
- campos de salida;
- transacción;
- comportamiento ante vacío, `NULL` y duplicado;
- interruptores de pantalla que lo consumen.

### 7.2 Caracterización

- prueba del comportamiento actual;
- captura del SQL base;
- orden y aliases;
- errores conocidos que deben conservarse;
- comparación de resultados si existe una consulta equivalente.

### 7.3 Extracción

- crear o ampliar el contrato;
- crear records de entrada y salida;
- implementar en `UniData*Repositorio`;
- registrar definiciones;
- inyectar catálogo y conexión;
- sustituir llamadas;
- retirar el SQL original;
- conservar fachada solo si tiene consumidores pendientes.

### 7.4 Pruebas

- sin perfil;
- perfil desactivado;
- perfil válido;
- parámetros incorrectos;
- campos de salida incorrectos;
- sentencia peligrosa o múltiple;
- fallo del perfil y éxito del SQL base;
- fallo del perfil y del SQL base;
- rollback antes del fallback, cuando sea escritura;
- repositorio falso para probar el dominio sin BBDD.

### 7.5 Cierre

- DUnitX Win32/Win64;
- Debug/Release;
- prueba de integración marcada cuando proceda;
- `git diff --check`;
- comprobación de dependencias;
- comprobación de SQL en dominio;
- manual y catálogo actualizados;
- informe de resultados del fascículo.

## 8. Gobierno de perfiles

1. El SQL de negocio se publica bajo `USUARIO_GRUPO_USUPER='Todos'`.
2. No habrá SQL diferente por usuario o grupo.
3. El interruptor `oGetSQLFromDB` sí puede variar por formulario y perfil.
4. Una fila existente nunca se sobrescribe automáticamente.
5. Una definición nueva se publica con SQL base, versión y huella.
6. Una definición retirada se marca obsoleta; no se reutiliza su clave.
7. Cambiar un SQL compartido exige revisar todos sus consumidores.
8. Desactivar una operación o una pantalla debe volver al SQL base sin
   desplegar otro ejecutable.
9. El SQL base nunca se elimina del binario.
10. Si el SQL base también falla, la excepción se propaga.

## 9. Riesgos y controles

| Riesgo | Control |
|---|---|
| Duplicar una escritura al hacer fallback | Política transaccional y rollback obligatorio |
| Romper varias pantallas con un SQL compartido | Registro de consumidores y pruebas por contrato |
| Crear un repositorio cajón de sastre | Interfaces pequeñas y división por caso de uso |
| Exponer SQL o `TDataSet` al dominio | Records e interfaces de resultado |
| Cambiar comportamiento durante la extracción | Pruebas de caracterización antes de mover |
| Parámetros dinámicos no parametrizables | Variantes enumeradas o fragmentos estructurales controlados |
| Perfiles incompatibles con una versión | Versión, huella, validación y fallback base |
| Publicación incompleta | Registro central, independiente de abrir pantallas |
| Ocultar deuda con exclusiones del script | Auditar cada falso positivo y no excluir unidades completas |
| Transacciones demasiado grandes | Un caso de uso por unidad de trabajo y pruebas de fallo |

## 10. Métricas de seguimiento

Después de cada fascículo se registrará:

| Métrica | Regla |
|---|---|
| SQL real en dominio | No puede aumentar |
| Unidades de dominio con SQL | No puede aumentar |
| Definiciones registradas | Debe igualar las operaciones migradas |
| Claves duplicadas | Cero |
| Lecturas con fallback probado | 100 % de las habilitadas |
| Escrituras con rollback probado | 100 % de las habilitadas |
| SQL personalizado por usuario | Cero |
| Dependencias `inLib* -> UniDAC` nuevas | Cero |
| Pruebas DUnitX nuevas | Al menos una por comportamiento extraído |
| Compilaciones afectadas | Debug/Release, Win32/Win64 |

La reducción se mide sobre el último techo monotónico cerrado. No se dará por
terminada una fase porque el SQL haya cambiado de fichero: debe haber
salido de la capa de dominio y quedar detrás del contrato.

## 11. Primeros fascículos recomendados

Orden inmediato:

1. SQL-2.3b: consultas de arqueo y tira de caja.
2. SQL-2.4: consultas pequeñas de Facturas y exportaciones.
3. SQL-2.5: consultas transversales de una sola responsabilidad.

SQL-0 y SQL-1 ya han validado la plataforma y los repositorios existentes.
El siguiente paso ataca lecturas con alto retorno y riesgo bajo. Las
materializaciones de compra no empiezan hasta que la política transaccional
y sus pruebas estén disponibles.
