# Factuzam Migrator (SQL Server → MariaDB)

Programa Delphi VCL independiente que migra los datos del ERP legacy
"Herreras" (SQL Server) hacia la base de datos `factuzam` (MariaDB).

Vive en su propia carpeta para no acoplarse al ejecutable principal y
compila contra los mismos componentes que el resto del proyecto:
**UniDAC** (Devart) con los providers `MySQLUniProvider` y
`SQLServerUniProvider`.

## Estructura

```
src/utilmigsqlsrv/
├── FactuzamMigrator.dpr           Programa principal
├── FactuzamMigrator.dproj         Proyecto Delphi (XE / RAD Studio)
├── FactuzamMigrator.res           Recurso (placeholder)
├── UMigConn.pas / .dfm            Data module con las dos TUniConnection
├── UMigEngine.pas                 Motor: registro, log, transacciones
├── UMigrator.pas / .dfm           Formulario principal (UI)
├── inLibMigEmpresas.pas           dbo.ocemp      → fza_empresas
├── inLibMigEmpleados.pas          dbo.ocemp      → fza_empleados
├── inLibMigAlmacenes.pas          dbo.ocalm      → fza_almacenes
├── inLibMigClientes.pas           dbo.occli      → fza_clientes
├── inLibMigProveedores.pas        dbo.ocpro      → fza_proveedores
├── inLibMigFamilias.pas           dbo.ocniv      → fza_articulos_familias
├── inLibMigAtributos.pas          dbo.occolor    → fza_atributos_valores + basicos
│                                  DISTINCT(ocarttal.Talla) → idem para tallas
├── inLibMigArticulos.pas          dbo.ocartp     → fza_articulos
├── inLibMigArticulosAtributos.pas dbo.ocartcol   → fza_articulos_atributos_basicos
│                                  dbo.ocarttal   → idem (asignaciones por art)
├── inLibMigArticulosSkus.pas      dbo.ocartbap   → fza_articulos_skus +
│                                                   fza_atributos_sku +
│                                                   fza_codigos_barras
├── inLibMigInventarios.pas        dbo.ocartacp   → fza_inventarios +
│                                                   fza_inventarios_lineas
├── inLibMigMovimientos.pas        dbo.ocmovarp   → fza_movimientos_almacen
│                                                   (+ reconstruye stockactual)
├── inLibMigVentas.pas             dbo.occaj      → fza_caja_operaciones +
│                                                   fza_caja_pagos +
│                                                   fza_depositos_cliente
├── inLibMigFacturas.pas           dbo.occaj/occajarp → fza_facturas +
│                                                   fza_facturas_lineas
├── inLibMigVentasMayor.pas        dbo.ocpedcli/ocalbcli/ocfaccli →
│                                                   pedidos, albaranes y
│                                                   facturas de venta mayor
├── inLibMigTallajes.pas           dbo.ocgrptal + ocgrptalnor →
│                                                  fza_atributos_conjuntos
│                                                  + _det
├── inLibMigArticulosTallajes.pas  ocartp.NroTallaje →
│                                                fza_articulos_conjuntos_asign
├── inLibMigEntorno.pas            occajas/ocseract/occtador/ocnivnro →
│                                                fza_almacenes_cajas +
│                                                fza_empresas_series +
│                                                fza_contadores +
│                                                CONTADOR_ART_FAM (familias)
├── inLibMigFotos.pas              dbo.ocartcol.ArchivoFoto →
│                                                PNG 300/600/real en disco +
│                                                fza_articulos_fotos
└── resultados/                    CSVs de muestra exportados desde SSMS
```

## Cómo usarlo

1. Abre `FactuzamMigrator.dproj` en RAD Studio (la misma versión que el
   proyecto principal).
2. Asegúrate de tener los providers UniDAC en el search path: en
   particular `SQLServerUniProvider` (suele venir con UniDAC pero
   no estaba activado en el `fzam` principal).
3. Compila y ejecuta.
4. En el formulario:
   - Configura las **cinco filas** de cada conexión (host, puerto,
     base, usuario, contraseña).
   - Pulsa "Probar conexión" en cada lado.
   - Marca las migraciones que quieras ejecutar (el listado respeta el
     orden de dependencias: formas de pago antes que clientes,
     empresas antes que almacenes, etc.).
   - Pulsa "Ejecutar migraciones" y revisa el log al pie.

El programa guarda los valores de las conexiones en
`%USERPROFILE%\Factuzam\migrator.ini`. Las contraseñas se guardan
cifradas con DPAPI (ligadas a la cuenta Windows del usuario), nunca en
claro; si el `.ini` se copia a otro equipo o usuario, las contraseñas no
se podrán descifrar y habrá que volver a teclearlas.

## Preparar la BBDD destino desde cero

El propio Migrator ofrece tres botones en la sección "Preparar BBDD
destino" para no depender de `factuzam_original.sql` (que se queda
obsoleto en cuanto el esquema cambia):

1. **Extraer esqueleto de BBDD viva…** — conecta a la BBDD que indiques
   en el panel "Destino" (típicamente la `factuzam` de desarrollo) y
   genera un `.sql` con:
   - `CREATE TABLE` de TODAS las tablas `fza_*` (vía `SHOW CREATE TABLE`
     → refleja el estado real, incluidos índices, defaults, comentarios).
   - `CREATE VIEW` de las vistas `vi_*`, ordenadas por dependencias
     internas entre vistas.
   - `CREATE PROCEDURE` / `FUNCTION` de las rutinas almacenadas.
   - **Datos de tablas SISTEMA solamente**: `fza_paises`, `fza_ivas_tipos`,
     `fza_ivas_zonas`, `fza_winforms`, `fza_metadatos`,
     `fza_generadorprocesos`, `fza_config_campos`. El resto (artículos,
     clientes, facturas…) sale vacío porque lo rellena el migrador.

2. **Crear BBDD destino (utf8mb4_spanish_ci)** — toma el nombre del
   campo "Base de datos" del panel destino y ejecuta
   `CREATE DATABASE IF NOT EXISTS … CHARACTER SET utf8mb4 COLLATE
   utf8mb4_spanish_ci`. Conecta vía la BBDD de sistema `mysql` para
   poder hacer el CREATE.

3. **Cargar esqueleto en destino…** — file picker para elegir el `.sql`
   generado en (1) y volcarlo a la BBDD destino. Usa `TUniScript` que
   maneja sentencias múltiples, comentarios y `DELIMITER` (necesario
   para procedures).

Flujo típico para empezar una migración limpia:

```
1. Apunta "Destino" a tu factuzam de desarrollo.
2. Click "Extraer esqueleto…" → guarda esqueleto_factuzam_AAAAMMDD.sql
3. Cambia "Base de datos" a factuzam_herreras (o el nombre que quieras).
4. Click "Crear BBDD destino"
5. Click "Cargar esqueleto…" → eliges el fichero de (2)
6. Marca las migraciones y dale a "Ejecutar".
```

Si se añade una nueva tabla seed al sistema, registrarla en
`inLibMigDumpEsqueleto.pas → TablasSistema` para que el esqueleto
también la incluya con datos.

## Cambios de esquema requeridos

Algunos mappers necesitan columnas nuevas en el destino que no existían
en la versión original. Para BBDD ya creadas hay que ejecutar antes el
script correspondiente; las BBDD creadas desde `factuzam_original.sql`
de este branch ya las traen:

| Migración    | Script idempotente para BBDD existente             |
|--------------|----------------------------------------------------|
| Proveedores  | `DESARROLLOS EN CURSO/proveedores_nombre.sql`      |
|              | (añade `fza_proveedores.NOMBRE_PRV varchar(200)`)  |
| Proveedores  | `DESARROLLOS EN CURSO/proveedores_pagos_defecto.sql` |
|              | (añade `CODIGO_FP_PRV` y `CODIGO_EMPBAN_PRV`; el   |
|              | migrador rellena `CODIGO_FP_PRV` desde `ocpro.TipoEfecto`) |
| Clientes     | `DESARROLLOS EN CURSO/widen_codigo_cli.sql`        |
|              | (amplía `CODIGO_CLI_*` de varchar(10) a varchar(20)|
|              | en clientes, facturas, albaranes y pedidos —       |
|              | origen guarda hasta 15 chars, no caben en 10)      |
| Familias     | `DESARROLLOS EN CURSO/familias_codigo_padre.sql`   |
|              | (añade `CODIGO_PADRE_FAM` y su índice — para       |
|              | preservar la jerarquía sección→familia del legacy: |
|              | "1401" tiene como padre "14"). |
| Inventarios  | `DESARROLLOS EN CURSO/widen_linea_invlin.sql`      |
|              | (amplía `LINEA_INVLIN` de varchar(4) → varchar(8). |
|              | Si un almacén legacy tiene >9999 SKUs en stock no  |
|              | cabe en 4 chars). |
| Empleados    | `DESARROLLOS EN CURSO/empleados_ampliar_ocemp.sql` |
|              | (añade datos de contacto/identificación de         |
|              | `dbo.ocemp` a `fza_empleados`, sin tocar usuarios).|

## Fotos legacy (dominio `fotos`)

`dbo.ocartcol.ArchivoFoto` guarda la ruta de la foto de cada
artículo+color **sin la carpeta raíz** (p.ej.
`\temp.34\85san francisco\3834.jpg`). El formulario añade dos campos,
persistidos en `migrator.ini`:

- **Raíz fotos legacy** — carpeta donde empiezan esas rutas
  (normalmente `C:\fotos`).
- **Destino fotos (appDirFotos)** — carpeta del sistema de fotos del
  Factuzam destino; admite tokens tipo `$(PUBLICO)\Factuzam\fotos`
  (se expanden con `inLibPathTokens` al ejecutar).
- **Hilos fotos** — tamaño del pool de conversión de imágenes dentro
  del dominio (2-5 recomendado; tope 8).

Para cada (Articulo, Color) con foto genera los tres PNG del esquema
estándar (`300/`, `600/`, `real/`) en la carpeta destino y registra la
fila en `fza_articulos_fotos` con `CODIGO_UNIDAD_FOT = ARTICULO/COLOR`
(mismo slot de color que el mapper de SKUs, para que el resolutor del
exe la encuentre por prefijo). Detalle completo en
`DESARROLLOS EN CURSO/migracion_fotos.md`.

El dominio corre en un **hilo independiente de las waves** (en paralelo
a toda la migración de datos) y, por dentro, reparte la conversión
(decodificar + 3 PNG por foto) entre los hilos del pool. Los hilos del
pool solo tocan ficheros; las filas de INSERT las encolan y las vuelca
a BBDD el hilo del dominio, porque la conexión UniDAC no admite uso
concurrente.

## Ejecución asíncrona y paralelismo

La migración corre en hilos de trabajo OmniThreadLibrary, no en el
hilo de UI. Mientras corre:
- El memo de progreso muestra una línea por dominio activo, con su
  contador "X / Y (Z%)" actualizándose en tiempo real.
- El botón "Ejecutar migraciones" cambia a "Cancelar". Al pulsarlo
  se termina el dominio en curso y se sale del bucle.
- Los botones de configuración (probar conexión, crear BBDD, cargar
  esqueleto, limpiar demo) se deshabilitan para evitar tocar las
  mismas `TUniConnection` que usan los workers.

### Paralelismo entre dominios

Los dominios se agrupan en **waves** según sus dependencias. Dentro
de una wave todos los dominios corren en **paralelo** (cada uno en su
propio hilo, con su propia pareja `TUniConnection` origen/destino —
UniDAC no soporta uso concurrente en una misma conexión). Las waves
se procesan secuencialmente: la siguiente arranca cuando todos los
workers de la actual han terminado.

| Wave | Dominios | Depende de |
|------|----------|------------|
| 0 | formas_pago · ivas_grupos · ivas · empresas · empleados · proveedores · familias · colores_maestros · tallas_maestras | — |
| 1 | almacenes · clientes · articulos · tallajes | Wave 0 |
| 2 | articulos_colores · articulos_tallas · articulos_tallajes_asign · skus | Wave 1 |
| 3 | inventarios · movimientos · ventas · pedidos_venta · albaranes_venta · pedidos_compra · albaranes_compra | Wave 2 |
| 4 | facturas | Wave 3 |
| 5 | facturas_venta_mayor | Wave 4 |

El dominio `fotos` **no entra en las waves**: se lanza en un hilo
independiente al principio de la corrida y avanza en paralelo a toda la
migración de datos (el coordinador lo espera tras la última wave).

`Parallel.ForEach<string>(aDeWave).Execute(...)` levanta `N` workers
(por defecto OmniThread elige según los núcleos disponibles) y los
alimenta con los códigos de dominio de la wave. Cada worker:
1. Clona `TUniConnection` origen + destino vía `dmMig.Clonar*`.
2. Crea un `TMigEngine.CreateClone` que reutiliza la lista de items y
   las callbacks del maestro pero con sus propias conexiones y
   contadores.
3. Llama `LocalEng.Ejecutar(codigo, Stats)` que lanza el mapper.
4. Acumula stats vía `TInterlocked.Add` sobre contadores compartidos.
5. Libera engine + conexiones al salir.

Si un mapper revienta dentro de su transacción, el motor hace
ROLLBACK del dominio (no de la wave), el contador de errores sube y
los demás workers de la wave siguen su curso.

Al cerrar el form mientras se ejecuta, se solicita cancelación y se
espera hasta 5 s a que los workers terminen el dominio en curso.

## Log de errores

Cada corrida del migrador escribe:

- `MemoLog`           — todo el log secuencial (info + saltos + errores).
- `MemoErrores`       — panel inferior rojo que solo recoge las líneas
                        marcadas con `!` (errores y avisos),
                        redimensionable con su splitter.
- `migrator_errores_YYYYMMDD_HHMMSS.log` en
  `%USERPROFILE%\Factuzam\` — fichero de texto con los mismos errores,
  para revisar después.

La ruta exacta del fichero se imprime en `MemoLog` al pulsar
"Ejecutar migraciones". Cualquier `LogError` del engine, `! error`
heredado de mappers antiguos o `FALLO TOTAL en X` cae a los tres
sitios a la vez.

## Bulk insert en mappers pesados

Para tablas grandes (`fza_articulos_atributos_basicos` con 266k+81k
filas de origen, futuros `fza_codigos_barras`, `fza_inventarios_lineas`,
etc.) usamos `TBulkInsert` del motor: agrupa filas en bloques de 1000
y las envía con UN `INSERT IGNORE INTO ... VALUES (...), (...), ...`
por bloque. Reduce drasticamente las roundtrips a MariaDB.

- `INSERT IGNORE` hace que las filas que choquen con la PK no
  aborten el batch (idempotencia automática).
- El buffer interno se vacía al llegar al `BatchMax` (default 1000)
  o al llamar `FlushPendiente` al final del bucle. El destructor
  también flush por seguridad.
- Mappers actualmente con bulk: `articulos_colores`, `articulos_tallas`.
- El resto de mappers (volúmenes < 50k filas) sigue con INSERT por
  fila parametrizado, más simple y con feedback más fino.

## Filosofía de los mappers

- Cada unidad `inLibMig<Dominio>.pas` exporta **una** función
  `Migrar<Dominio>(Eng, var Stats)`. Esa es toda la API.
- Todas las inserciones del dominio van **dentro de una transacción**;
  si revienta una fila, se hace rollback completo del dominio.
- Son **idempotentes**: si la clave primaria destino ya existe, se
  contabiliza en `Stats.Saltadas` y se sigue.
- Las cuatro columnas de auditoría (`INSTANTE_ALTA`, `INSTANTE_MODIF`,
  `USUARIO_ALTA`, `USUARIO_MODIF`) las pone siempre el motor con `Now()`
  y el usuario configurado en la UI (`MIGRADOR` por defecto).

## Añadir un nuevo dominio

1. Crea `inLibMig<NuevoDominio>.pas` siguiendo el patrón de los
   existentes.
2. Añade la unidad al `.dpr` y al `.dproj`.
3. Registra la migración en `UMigrator.RegistrarMigraciones`, eligiendo
   bien la posición para que las dependencias se cumplan.

## Heurísticas y limitaciones de la primera versión

- **IVAs**: el origen guarda histórico fila a fila (un porcentaje por
  fecha y tipo). El destino guarda un registro por código de IVA con
  varios porcentajes en columnas. Mapeamos el `PorIVA` mayor como
  `PORCENTAJE_NORMAL_IVA` y dejamos reducido/súper/exento a 0. El
  usuario tendrá que afinar después.
- **Almacenes**: el destino tiene `CODIGO_ALM_ALM` único global; el
  origen indexa por `(Empresa, Almacen)`. Generamos `CODIGO_ALM_ALM =
  E<empresa>-A<almacen>` para garantizar unicidad.
- **Tipo de IVA por artículo**: el origen guarda un entero; el destino
  un char(2) ('N'/'R'/'S'/'E'). Por defecto migramos como `'N'`. Hay
  que repasar después.
- **Forma de pago en cliente**: en origen es texto descriptivo +
  TipoEfecto (int). Usamos TipoEfecto como CODIGO_FP_CLI; debe existir
  previamente en `fza_formas_pago` (por eso "formas_pago" va antes
  que "clientes" en el listado).
- **Familias de artículos**: se migran desde `dbo.ocniv` filtrando
  `Nivel IN (2, 4)`. Origen tiene 194 filas; de ellas:
  - 12 con Nivel=2 (SECCIONES: `SEÑORA`, `CABALLERO`...), código 2 chars.
  - 181 con Nivel=4 (FAMILIAS: `BLUSA M/L`, `JERSEY SRA`...), código 4 chars.
  - 1 con Nivel=1 (outlier, se descarta).

  Las dos jerarquías van a la misma tabla destino (`fza_articulos_familias`)
  porque el destino no modela explícitamente la relación
  sección→familia. Las familias (Nivel=4) se insertan primero para que
  la "default" sea una familia real, no una sección.

  El código se conserva literal: `ocartp.Familia` ya guarda el código
  de 4 chars, así que `CODIGO_FAM_ART` (que rellena `inLibMigArticulos`
  desde ahí) cuadra sin transformación con `CODIGO_FAM_FAM` destino.

  La columna `Estado` del origen marca `ESACTIVO_FAM='N'` solo cuando
  vale `'B'` (baja); cualquier otro valor (NULL, vacío) se asume activo.
- **Atributos (colores y tallas)**: el modelo destino es muy rico
  (variación → ejes → valores → básicos canónicos). El migrador hace
  la versión mínima:
  - Asegura que existe la variación `TC` con sus ejes `CO` y `TAL`.
  - Inserta en `fza_atributos_valores` el catálogo (un valor por color
    o talla, ID_VA='CO'/'TAL', AV=texto en mayúsculas).
  - Inserta en `fza_atributos_basicos` con el HEX (cuando viene en
    `occolor.ColorPaleta`) y el nombre canónico.
  - Después, las asignaciones por artículo (`ocartcol`, `ocarttal`) se
    vuelcan a `fza_articulos_atributos_basicos`.
- **No se migra todavía** `fza_articulos_conjuntos_asign` (qué set de
  tallas/colores concreto usa cada artículo). Para que un artículo se
  comporte como "tiene variaciones" en la UI basta con que
  `fza_articulos.TIPO_VARIACION_ART` sea `'TC'`/`'T'`/`'C'`, cosa que
  ya hace `inLibMigArticulos` a partir de `HayColores` y `HayTallas`.
  El ajuste fino de qué conjunto concreto le toca a cada artículo
  habrá que hacerlo manual o con un script aparte una vez aterrice
  el dato.
