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
├── inLibMigFormasPago.pas         dbo.octipefe   → fza_formas_pago
├── inLibMigIvasGrupos.pas         dbo.ocgrpiva   → fza_ivas_grupos
├── inLibMigIvas.pas               dbo.octipiva   → fza_ivas
├── inLibMigEmpresas.pas           dbo.ocemp      → fza_empresas
├── inLibMigAlmacenes.pas          dbo.ocalm      → fza_almacenes
├── inLibMigClientes.pas           dbo.occli      → fza_clientes
├── inLibMigFamilias.pas           dbo.ocartniv   → fza_articulos_familias
├── inLibMigAtributos.pas          dbo.occolor    → fza_atributos_valores + basicos
│                                  DISTINCT(ocarttal.Talla) → idem para tallas
├── inLibMigArticulos.pas          dbo.ocartp     → fza_articulos
├── inLibMigArticulosAtributos.pas dbo.ocartcol   → fza_articulos_atributos_basicos
│                                  dbo.ocarttal   → idem (asignaciones por art)
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

El programa guarda los valores de las conexiones (sin contraseñas) en
`%USERPROFILE%\Factuzam\migrator.ini`.

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
- **Familias de artículos**: se migran desde `ocartniv` con código
  numérico padding 3 (001, 002...). En `inLibMigArticulos` el campo
  `Familia` se copia tal cual del origen — si el origen guarda el código
  como entero corto ('1', '2') tampoco va a cuadrar con la familia
  migrada ('001'). Ejecuta primero `sample_export_ssms.sql` para ver
  cómo es el campo `ocartp.Familia` real y ajustamos el formateo si
  hace falta.
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
