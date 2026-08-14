# Libro de estilo de la base de datos Factuzam

Manual práctico para añadir tablas, columnas, índices, vistas y procedimientos respetando la convención de nombres del esquema.

---

## 1. Principios

1. **Toda columna lleva al final un sufijo que identifica su tabla**, salvo las columnas de auditoría.
2. **El sufijo es siempre el mismo para una tabla dada**: si la tabla `fza_articulos` tiene sufijo `ART`, todas sus columnas terminan en `_ART`.
3. **Todos los identificadores van en MAYÚSCULAS** y separados por guion bajo (`_`), excepto los nombres de tabla que van en minúsculas con prefijo `fza_`.
4. **Las claves foráneas lógicas** (no hay FOREIGN KEY declaradas, son convenciones) se nombran con el patrón `<TIPO_ID>_<SUFIJO_DESTINO>_<SUFIJO_TABLA>`.
5. **Los booleanos** (columnas `varchar(1)` con valores `'S'`/`'N'`) llevan prefijo `ES` sin guion bajo.
6. **Los índices** se llaman `IDX_<SUFIJO_TABLA>_<columnas>` o `UQ_<SUFIJO_TABLA>_<columnas>` para únicos.
7. **Todas las tablas** tienen ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci.
8. **No hay funciones ni triggers** en la bbdd sólo hay procedimientos, se evita el uso de funciones y triggers. Se sustituirán por procedimientos almacenados.
9. **No hay FOREIGN KEYS** en la bbdd. Sólo hay índices para conectar dos tablas unidas por el mismo campo.
10. **El prefijo para las tablas es `fza_nombre_tabla`** para diferenciar de
    pruebas u otras integraciones.
11. **Nunca se modifica `factuzam_original.sql`.** Es el modelo de una
    instalación limpia. Todo cambio vive en un script independiente dentro
    de `DESARROLLOS EN CURSO/`.
12. **Todo cambio de esquema es idempotente.** Antes de crear una tabla,
    columna o índice se consulta `INFORMATION_SCHEMA` o se usa una cláusula
    `IF NOT EXISTS` compatible con la versión objetivo de MariaDB.
13. **Cada script, vista y procedimiento tiene una responsabilidad.** Su
    nombre indica el cambio o caso de uso y no mezcla dominios independientes.
14. **Los valores externos siempre se parametrizan.** El SQL dinámico solo
    concatena identificadores validados mediante una lista blanca.
---

## 2. Catálogo de sufijos por tabla

Cuando crees una tabla nueva, **registra su sufijo** aquí y en el código del normalizador (`UNormalizerEngine.pas` → `InitDefaults`).

| Tabla                                | Sufijo    |
|--------------------------------------|-----------|
| `fza_albaranes`                      | `ALB`     |
| `fza_albaranes_compra`               | `ALBC`    |
| `fza_albaranes_compra_celdas`        | `ALBCCEL` |
| `fza_albaranes_compra_lineas`        | `ALBCLIN` |
| `fza_albaranes_lineas`               | `ALBLIN`  |
| `fza_almacenes`                      | `ALM`     |
| `fza_almacenes_cajas`                | `ALMCAJ`  |
| `fza_articulos`                      | `ART`     |
| `fza_articulos_atributos_basicos`    | `AAB`     |
| `fza_articulos_conjuntos_asign`      | `ACA`     |
| `fza_articulos_familias`             | `FAM`     |
| `fza_articulos_propiedades`          | `ARTPROP` |
| `fza_articulos_proveedores`          | `AP`      |
| `fza_articulos_skus`                 | `SKU`     |
| `fza_articulos_skus_costes`          | `SKUC`    |
| `fza_articulos_stockactual`          | `STK`     |
| `fza_articulos_tarifas`              | `ARTTAR`  |
| `fza_articulos_vinculos`             | `ARTVIN`  |
| `fza_atributos_basicos`              | `ATB`     |
| `fza_atributos_conjuntos`            | `AC`      |
| `fza_atributos_conjuntos_det`        | `ACD`     |
| `fza_atributos_sku`                  | `SA`      |
| `fza_atributos_valores`              | `AV`      |
| `fza_atributos_valores_info`         | `AVI`     |
| `fza_bancos`                         | `BAN`     |
| `fza_caja_arqueos`                   | `ARQ`     |
| `fza_caja_formas_pago`               | `CFP`     |
| `fza_caja_operaciones`               | `OPCAJA`  |
| `fza_caja_pagos`                     | `PAGO`    |
| `fza_caja_vales`                     | `VL`      |
| `fza_clientes`                       | `CLI`     |
| `fza_codigos_barras`                 | `CB`      |
| `fza_compras_plantillas`             | `SESPL`   |
| `fza_compras_plantillas_kits`        | `SESPLKIT`|
| `fza_compras_plantillas_kits_det`    | `SESPLKITD`|
| `fza_compras_plantillas_props`       | `SESPLPROP`|
| `fza_compras_sesiones`               | `SES`     |
| `fza_compras_sesiones_celdas`        | `SESCEL`  |
| `fza_compras_sesiones_kits`          | `SESKIT`  |
| `fza_compras_sesiones_kits_det`      | `SESKITD` |
| `fza_compras_sesiones_lineas`        | `SESLIN`  |
| `fza_compras_sesiones_lineas_filas`  | `SESFIL`  |
| `fza_compras_sesiones_lineas_filas_atr`| `SESFILAT`|
| `fza_compras_sesiones_lineas_props`  | `SESLPROP`|
| `fza_compras_sesiones_lineas_skus_precios` | `SESLINSKU`|
| `fza_compras_sesiones_documentos`    | `SESDOC`  |
| `fza_compras_sesiones_props`         | `SESPROP` |
| `fza_config_campos`                  | `CC`      |
| `fza_contadores`                     | `CON`     |
| `fza_depositos_cliente`              | `DEP`     |
| `fza_documentos_trabajo_compartidos` | `DTC`     |
| `fza_documentos_trabajo`             | `DTR`     |
| `fza_documentos_trabajo_lineas`      | `DTL`     |
| `fza_devoluciones_compra`            | `DEVC`    |
| `fza_devoluciones_compra_celdas`     | `DEVCCEL` |
| `fza_devoluciones_compra_lineas`     | `DEVCLIN` |
| `fza_efectos_compra`                 | `EFEC`    |
| `fza_efectos_venta`                  | `EFV`     |
| `fza_empleados`                      | `EMPL`    |
| `fza_errores_envios`                 | `ERENV`   |
| `fza_empresas`                       | `EMP`     |
| `fza_empresas_bancos`                | `EMPBAN`  |
| `fza_empresas_retenciones`           | `EMPRET`  |
| `fza_empresas_series`                | `EMPSER`  |
| `fza_facturacion_caja_periodos`      | `FACPER`  |
| `fza_facturas`                       | `FAC`     |
| `fza_facturas_compra`                | `FACC`    |
| `fza_facturas_compra_celdas`         | `FACCCEL` |
| `fza_facturas_compra_lineas`         | `FACCLIN` |
| `fza_facturas_consolidaciones`       | `FACCON`  |
| `fza_facturas_lineas`                | `FACLIN`  |
| `fza_facturas_operaciones_caja`      | `FACOP`   |
| `fza_facturas_relaciones`            | `FACREL`  |
| `fza_facturas_pagos`                 | `FACPAG`  |
| `fza_familias_atributos`             | `FA`      |
| `fza_familias_atributos_defecto`     | `FAD`     |
| `fza_familias_claves_info_defecto`   | `FCI`     |
| `fza_filtros_guardados`              | `FILT`    |
| `fza_filtros_guardados_compartidos`  | `FILTC`   |
| `fza_formas_pago`                    | `FP`      |
| `fza_generadorprocesos`              | `GP`      |
| `fza_inventarios`                    | `INV`     |
| `fza_inventarios_lineas`             | `INVLIN`  |
| `fza_ivas`                           | `IVA`     |
| `fza_ivas_grupos`                    | `IVAGRP`  |
| `fza_ivas_tipos`                     | `IVATIP`  |
| `fza_ivas_zonas`                     | `IVAZON`  |
| `fza_metadatos`                      | `META`    |
| `fza_movimientos_almacen`            | `MOV`     |
| `fza_paises`                         | `PAI`     |
| `fza_pedidos`                        | `PED`     |
| `fza_pedidos_lineas`                 | `PEDLIN`  |
| `fza_pedidos_mensajes`               | `PEDMSG`  |
| `fza_prestashop_cola`                | `PSCOLA`  |
| `fza_prestashop_cola_eventos`        | `PSCEV`   |
| `fza_propiedades`                    | `PROP`    |
| `fza_propiedades_valores`            | `PV`      |
| `fza_proformas_caja`                 | `PROCAJ`  |
| `fza_proformas_caja_lineas`          | `PROCLIN` |
| `fza_proveedores`                    | `PRV`     |
| `fza_proveedores_familias`           | `PF`      |
| `fza_proveedores_familias_conjuntos` | `PFC`     |
| `fza_proveedores_kits`               | `PRVKIT`  |
| `fza_proveedores_kits_det`           | `PRVKITD` |
| `fza_recibos`                        | `REC`     |
| `fza_remesas_compra`                 | `REMC`    |
| `fza_remesas_venta`                  | `REMV`    |
| `fza_tarifas`                        | `TAR`     |
| `fza_tarifas_cambios`                | `TARC`    |
| `fza_tarifas_cambios_lineas`         | `TARCLIN` |
| `fza_tipos_documentos`               | `TD`      |
| `fza_tipos_efecto`                   | `TEFE`    |
| `fza_traducciones`                   | `TRAD`    |
| `fza_traspasos_solicitudes`          | `TRSOL`   |
| `fza_traspasos_solicitudes_lineas`   | `TRSOLLIN`|
| `fza_unidades_medida`                | `UNIMED`  |
| `fza_usuarios`                       | `USU`     |
| `fza_usuarios_grupos`                | `USUGRP`  |
| `fza_usuarios_perfiles`              | `USUPER`  |
| `fza_valores_defecto`                | `VD`      |
| `fza_variaciones`                    | `VAR`     |
| `fza_variaciones_atributos`          | `VA`      |
| `fza_ventas_ws_cola`                 | `VWSC`    |
| `fza_ventas_ws_cola_intentos`        | `VWSCI`   |
| `fza_verifactu_cadena`               | `VFCAD`   |
| `fza_verifactu_cola`                 | `VFCOLA`  |
| `fza_verifactu_eventos`              | `LOG`     |
| `fza_winforms`                       | `WINF`    |

### Reglas para elegir un sufijo nuevo

- **3-6 letras** en mayúsculas. Más corto es mejor; nunca menos de 2.
- **Único** dentro del catálogo. Si choca con uno existente, alarga el del nuevo.
- **Mnemotécnico**: que evoque el nombre de la tabla. Para tablas compuestas (`fza_X_Y`), combina (ejemplos: `fza_facturas_lineas → FACLIN`, `fza_caja_formas_pago → CFP`).
- **Plurales**: la tabla va en plural (`fza_articulos`), el sufijo en singular (`ART`).

---

## 3. Nombres de columna

### 3.1 Estructura general

```
<NUCLEO>_<SUFIJO_TABLA>
```

Ejemplos (tabla `fza_clientes`, sufijo `CLI`):

```
NIF_CLI
NOMBRE_CLI
DIRECCION_CLI
SALDO_CLI
ESACTIVO_CLI
```

### 3.2 Prefijos por tipo de dato

Para que un programador lea el nombre y sepa al instante con qué tipo de dato está trabajando, los nombres de columna usan **prefijos canónicos según el tipo**. Esto es una convención estricta y aplica a TODA columna nueva.

**Enteros** (cantidades discretas, posiciones, contadores):

| Prefijo      | Uso                                                    | Ejemplos                                |
|--------------|--------------------------------------------------------|-----------------------------------------|
| `ORDEN_`     | Orden de presentación o de proceso                     | `ORDEN_CLI`, `ORDEN_LINEA_FACLIN`       |
| `CANTIDAD_`  | Unidades, número de elementos contables                | `CANTIDAD_FACLIN`, `CANTIDAD_INVLIN`    |
| `LINEA_`     | Número de línea dentro de un documento                 | `LINEA_FACLIN`, `LINEA_PEDLIN`          |
| `NUMERO_`    | Numerador identificativo (no FK)                       | `NUMERO_FAC`, `NUMERO_PED`              |
| `CONTADOR_`  | Contador acumulado                                     | `CONTADOR_LINEAS_FAC`                   |

**Monedas y decimales** (todos `DECIMAL` o `FLOAT`, mismo tipo):

| Prefijo        | Uso                                              | Ejemplos                                   |
|----------------|--------------------------------------------------|--------------------------------------------|
| `VALOR_`       | Valor numérico genérico (no monetario)           | `VALOR_AVI`                                |
| `TOTAL_`       | Total acumulado o calculado, monetario           | `TOTAL_FAC`, `TOTAL_BASES_FAC`             |
| `PRECIO_`      | Precio unitario o tarifado, monetario            | `PRECIO_VENTA_ART`, `PRECIO_ULT_COMPRA_AP` |
| `PORCENTAJE_`  | Porcentaje (0-100), siempre como decimal         | `PORCENTAJE_IVAN_FAC`, `PORCENTAJE_RER_FAC`|
| `IMPORTE_`     | Importe puntual de una operación                 | `IMPORTE_FACPAG`                           |

**Notas importantes:**

- Para porcentajes, NO usar abreviaturas como `PORCEN_` o `PCT_`. Siempre `PORCENTAJE_` completo. Si los actuales `PORCEN_*` ya están en producción, son legacy y se renombran al pasar el normalizador.
- `TOTAL_` y `PRECIO_` son del mismo tipo SQL (`DECIMAL(18,4)` o equivalente); se diferencian por **semántica**: `PRECIO_` es unitario o de tarifa, `TOTAL_` es agregado o calculado.
- `IMPORTE_` se reserva para movimientos puntuales (un pago, un cargo concreto). Si dudas entre `IMPORTE_` y `TOTAL_`, usa `TOTAL_`.
- `VALOR_` se usa cuando el campo no es estrictamente dinero (un coeficiente, una métrica, un valor de configuración numérico).

**Booleanos**: ver §3.5 (prefijo `ES`).

**Fechas e instantes**: ver §3.6 (prefijos `FECHA_` e `INSTANTE_`).

### 3.3 Columna que es la clave primaria de la tabla

Usa `CODIGO_<SUFIJO>` o `ID_<SUFIJO>`. **Nunca repitas el concepto**:

```
✓  CODIGO_CLI       en fza_clientes
✗  CODIGO_CLIENTE_CLI   ← redundante
✗  CODIGO_CLIENTE       ← le falta el sufijo
```

Cuando la tabla tiene un sufijo simple cuyo concepto largo aparece dentro del nombre de columna, **se sustituye** el concepto por el sufijo:

```
fza_articulos:   CODIGO_ARTICULO  →  CODIGO_ART
fza_almacenes:   NOMBRE_ALMACEN   →  NOMBRE_ALM
fza_clientes:    NIF_CLIENTE      →  NIF_CLI
```

### 3.4 Columna FK lógica (apunta a otra tabla)

Patrón general:

```
<TIPO_ID>_<SUFIJO_DESTINO>_<SUFIJO_TABLA>
```

Donde `TIPO_ID` ∈ `{ CODIGO, ID, NOMBRE, SERIE, NUMERO }`.

| Concepto                       | En tabla...                     | Nombre              |
|--------------------------------|---------------------------------|---------------------|
| FK a `fza_articulos`           | `fza_facturas_lineas`           | `CODIGO_ART_FACLIN` |
| FK a `fza_clientes`            | `fza_facturas`                  | `CODIGO_CLI_FAC`    |
| FK a `fza_empresas`            | `fza_pedidos`                   | `CODIGO_EMP_PED`    |
| FK a `fza_formas_pago`         | `fza_clientes`                  | `CODIGO_FP_CLI`     |
| FK a `fza_paises`              | `fza_clientes`                  | `CODIGO_PAI_CLI`    |
| FK a `fza_facturas`            | `fza_recibos`                   | `NUMERO_FAC_REC` y `SERIE_FAC_REC` |
| FK a `fza_atributos_conjuntos` | `fza_articulos_conjuntos_asign` | `ID_AC_ACA`         |

### 3.5 Booleanos

Columna `varchar(1)` que toma `'S'` o `'N'`. Prefijo `ES` **sin guion bajo**:

```
ESACTIVO_CLI
ESDEFECTO_FP
ESBLOQUEADO_USU
ESOBLIGATORIO_FA
ESGENERACION_AUTO_PFC
```

### 3.6 Fechas e instantes

Hay dos tipos de columnas temporales con prefijos diferentes:

| Prefijo      | Tipo SQL    | Uso                                                  | Ejemplos                                |
|--------------|-------------|------------------------------------------------------|-----------------------------------------|
| `FECHA_`     | `date`      | Fecha sin hora (cuando la hora es irrelevante)       | `FECHA_FAC`, `FECHA_VALIDEZ_AP`         |
| `INSTANTE_`  | `datetime`  | Momento exacto con fecha y hora                      | `INSTANTE_ALTA`, `INSTANTE_MODIF`       |

Reglas:
- Para campos de **vencimiento, validez, contables, fiscales** usa `FECHA_` (la hora no aporta valor).
- Para campos de **auditoría, log, eventos del sistema** usa `INSTANTE_`.
- Las cuatro columnas de auditoría (`INSTANTE_ALTA`, `INSTANTE_MODIF`, `USUARIO_ALTA`, `USUARIO_MODIF`) están exentas de sufijo de tabla, ver §3.7.

### 3.7 Auditoría (sin sufijo de tabla)

Estas cuatro columnas son comunes a casi todas las tablas y **mantienen siempre los mismos nombres**:

```
INSTANTE_ALTA      datetime  NOT NULL
USUARIO_ALTA       varchar(50)
INSTANTE_MODIF     datetime  NULL
USUARIO_MODIF      varchar(50) NULL
```

### 3.8 Abreviaturas estándar

Estas son las abreviaturas oficiales. **No inventes otras**.

| Abreviatura corta | Forma desplegada    |
|-------------------|---------------------|
| `NUMERO`          | número              |
| `CODIGO_POSTAL`   | código postal       |
| `PORCENTAJE`      | porcentaje          |
| `FORMA_PAGO`      | forma de pago       |
| `RAZON_SOCIAL`    | razón social        |
| `TIPO_DOCUMENTO`  | tipo de documento   |
| `TIPO_IVA`        | tipo de IVA         |
| `PRECIO_VENTA`    | precio de venta     |
| `PRECIO_SALIDA`   | precio de salida    |
| `PRECIO_FINAL`    | precio final        |
| `ALMACEN_DEFECTO` | almacén por defecto |

**Nunca uses**: `NRO`, `CPOSTAL`, `PORCEN`, `FORMAP`, `RAZONSOCIAL`, `TIPODOC`, `TIPOIVA`, `PRECIOSALIDA`, `ALMACENDEF`. Estas formas están desterradas.

### 3.9 Casos prohibidos

```
✗  NRO_FACTURA_REC          (usar NUMERO_FAC_REC)
✗  CODIGO_CLIENTE_CLI       (usar CODIGO_CLI)
✗  ES_ACTIVO_CLI            (usar ESACTIVO_CLI, sin guion tras ES)
✗  ACTIVO_CLI               (los booleanos llevan ES)
✗  INSTANTEALTA_CLI         (las auditoría no llevan sufijo)
✗  CodigoCliente            (sin CamelCase)
```

---

## 4. Cómo crear una tabla nueva

### 4.1 Pasos

1. Crea un script idempotente en `DESARROLLOS EN CURSO/`. No modifiques
   `factuzam_original.sql`.
2. Define el nombre de la tabla en plural y minúsculas:
   `fza_<nombre_plural>`.
3. Asigna un sufijo único de 3-6 letras y añádelo al catálogo de la sección 2.
4. Define las columnas siguiendo las reglas de la sección 3.
5. Define los índices siguiendo la sección 6 y comprueba su existencia.
6. Registra el sufijo y los conceptos propios en
   `UNormalizerEngine.pas` → `InitDefaults` (instrucciones en la sección 8).
7. Añade la verificación y, si el cambio es destructivo, el rollback.

### 4.2 Ejemplo: tabla `fza_promociones`

Sufijo elegido: `PROMO`. Vamos a registrar promociones que aplican a una empresa, opcionalmente a una familia de artículos, durante un rango de fechas, con un porcentaje de descuento.

```sql
CREATE TABLE IF NOT EXISTS `fza_promociones` (
  `CODIGO_PROMO`               varchar(20)   NOT NULL,
  `NOMBRE_PROMO`               varchar(100)  NOT NULL,
  `DESCRIPCION_PROMO`          varchar(500)  DEFAULT NULL,
  `CODIGO_EMP_PROMO`           varchar(20)   NOT NULL,        -- FK a fza_empresas
  `CODIGO_FAM_PROMO`           varchar(20)   DEFAULT NULL,    -- FK a fza_articulos_familias
  `FECHA_INICIO_PROMO`         date          NOT NULL,
  `FECHA_FIN_PROMO`            date          NOT NULL,
  `PORCENTAJE_DESCUENTO_PROMO` decimal(5,2)  NOT NULL,
  `PRECIO_MINIMO_PROMO`        decimal(19,6) DEFAULT NULL,
  `ESACUMULABLE_PROMO`         varchar(1)    NOT NULL DEFAULT 'N',
  `ESACTIVO_PROMO`             varchar(1)    NOT NULL DEFAULT 'S',
  `INSTANTE_ALTA`              datetime      NOT NULL,
  `USUARIO_ALTA`               varchar(50)   NOT NULL,
  `INSTANTE_MODIF`             datetime      DEFAULT NULL,
  `USUARIO_MODIF`              varchar(50)   DEFAULT NULL,
  PRIMARY KEY (`CODIGO_PROMO`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_spanish_ci;
CREATE INDEX IF NOT EXISTS `IDX_PROMO_EMP`
  ON `fza_promociones` (`CODIGO_EMP_PROMO`);
CREATE INDEX IF NOT EXISTS `IDX_PROMO_FAM`
  ON `fza_promociones` (`CODIGO_FAM_PROMO`);
CREATE INDEX IF NOT EXISTS `IDX_PROMO_FECHA_FIN`
  ON `fza_promociones` (`FECHA_FIN_PROMO`);
```

Observaciones:

- `CODIGO_PROMO` es la PK, no lleva concepto duplicado.
- `CODIGO_EMP_PROMO` y `CODIGO_FAM_PROMO` siguen el patrón `<TIPO_ID>_<SUFIJO_DESTINO>_<SUFIJO_TABLA>`.
- `ESACUMULABLE_PROMO` y `ESACTIVO_PROMO` son booleanos `varchar(1)`.
- Las cuatro columnas de auditoría no llevan sufijo `_PROMO`.

---

## 5. Cómo añadir una columna a una tabla existente

Nunca se entrega un `ALTER TABLE` desnudo. El patrón canónico comprueba el
catálogo y prepara únicamente la operación que falta:

```sql
SET @sExisteCol := (
  SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'fza_clientes'
     AND COLUMN_NAME = 'ESVIP_CLI'
);
SET @sSql := IF(
  @sExisteCol = 0,
  'ALTER TABLE fza_clientes
     ADD COLUMN ESVIP_CLI varchar(1) NOT NULL DEFAULT ''N''',
  'SELECT ''ESVIP_CLI ya existe; se omite'' AS info'
);
PREPARE stmt FROM @sSql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
```

Para índices se consulta `INFORMATION_SCHEMA.STATISTICS`; para tablas,
`INFORMATION_SCHEMA.TABLES`. El ejemplo completo de referencia es
`DESARROLLOS EN CURSO/proveedores_nombre.sql`.

Si la columna es una FK lógica, mantiene el patrón de §3.4 y añade un índice
idempotente. Una columna `NOT NULL` sobre una tabla con datos se migra en
fases: columna nullable, relleno verificable y restricción final.

---

## 6. Índices

### 6.1 Convención de nombres

```
IDX_<SUFIJO_TABLA>_<columnas_abreviadas>     → índice normal
UQ_<SUFIJO_TABLA>_<columnas_abreviadas>      → índice único
```

Las **columnas abreviadas** son los nombres de las columnas indexadas pero **sin el sufijo de tabla** (porque el sufijo ya está en el nombre del índice).

### 6.2 Ejemplos

```sql
-- Índice simple en CODIGO_EMP_FAC de la tabla fza_facturas
CREATE INDEX IF NOT EXISTS `IDX_FAC_EMP`
  ON `fza_facturas` (`CODIGO_EMP_FAC`);
-- Índice compuesto en CODIGO_CLI_FAC + FECHA_FAC
CREATE INDEX IF NOT EXISTS `IDX_FAC_CLI_FECHA`
  ON `fza_facturas` (`CODIGO_CLI_FAC`, `FECHA_FAC`);
-- Índice único en NIF_CLI
CREATE UNIQUE INDEX IF NOT EXISTS `UQ_CLI_NIF`
  ON `fza_clientes` (`NIF_CLI`);
-- Índice compuesto único: serie + número de factura
CREATE UNIQUE INDEX IF NOT EXISTS `UQ_FAC_SERIE_NUMERO`
  ON `fza_facturas` (`SERIE_FAC`, `NUMERO_FAC`);
```

### 6.3 Reglas

- Si el nombre supera 64 caracteres (límite de MySQL), trunca; mantén siempre el prefijo `IDX_<SUF>_`.
- No incluyas guiones bajos a la izquierda ni a la derecha del prefijo.
- Para una columna sola, el nombre del índice contiene esa columna y nada más.

---

## 7. Vistas y procedimientos

### 7.1 Convención de nombres

| Tipo            | Prefijo | Ejemplo                            |
|-----------------|---------|------------------------------------|
| Vista           | `VI_`   | `VI_FAC_PENDIENTES_COBRO`          |
| Procedimiento   | `PRC_`  | `PRC_FAC_INSERT`, `PRC_REC_ANULAR` |
| Función legado  | `FN_`   | `FN_CLI_SALDO_ACTUAL`              |
| Trigger legado  | `TRG_`  | `TRG_FAC_BI`, `TRG_MOV_AU`         |

Para triggers, el sufijo después del nombre de tabla indica el evento:

- `BI` = Before Insert, `AI` = After Insert
- `BU` = Before Update, `AU` = After Update
- `BD` = Before Delete, `AD` = After Delete

Las filas de función y trigger documentan objetos heredados. No autorizan
crear otros nuevos: la regla de §1.8 permanece vigente.

### 7.2 Ejemplo de vista

```sql
CREATE OR REPLACE VIEW `VI_FAC_PENDIENTES_COBRO` AS
SELECT
  F.`SERIE_FAC`,
  F.`NUMERO_FAC`,
  F.`FECHA_FAC`,
  F.`CODIGO_CLI_FAC`,
  C.`NOMBRE_CLI`,
  F.`TOTAL_FAC`,
  F.`SALDO_PENDIENTE_FAC`
FROM `fza_facturas` F
INNER JOIN `fza_clientes` C ON C.`CODIGO_CLI` = F.`CODIGO_CLI_FAC`
WHERE F.`SALDO_PENDIENTE_FAC` > 0
  AND F.`ESANULADA_FAC` = 'N';
```

Observaciones:

- Los alias de tabla son cortos y mayúsculos (`F`, `C`, `FL`).
- Las columnas se referencian siempre con su tabla (`F.CODIGO_CLI_FAC`), nunca sueltas.
- En la vista no hay nombres de columna nuevos: se exponen los originales con su sufijo. Si necesitas un alias, hazlo solo cuando el nombre original choque entre tablas.

### 7.3 Ejemplo de procedimiento

Convención de parámetros:

- Nombre: `p_<descriptivo>` en mayúsculas y guion bajo. **No** lleva sufijo de tabla.
- Tipo: el mismo que la columna real, no más laxo.

```sql
DELIMITER $$
CREATE OR REPLACE PROCEDURE `PRC_FAC_ANULAR` (
  IN  p_SERIE         varchar(10),
  IN  p_NUMERO        varchar(20),
  IN  p_USUARIO       varchar(50),
  IN  p_MOTIVO        varchar(500),
  OUT p_RESULTADO     int
)
BEGIN
  DECLARE v_existe int DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_RESULTADO = -1;
    RESIGNAL;
  END;
  START TRANSACTION;
  SELECT EXISTS(
    SELECT 1
      FROM `fza_facturas`
     WHERE `SERIE_FAC` = p_SERIE
       AND `NUMERO_FAC` = p_NUMERO
       AND `ESANULADA_FAC` = 'N'
  ) INTO v_existe;
  IF v_existe = 0 THEN
    SET p_RESULTADO = 0;          -- no existe o ya estaba anulada
    ROLLBACK;
  ELSE
    UPDATE `fza_facturas`
       SET `ESANULADA_FAC`         = 'S',
           `MOTIVO_ANULACION_FAC`  = p_MOTIVO,
           `INSTANTE_MODIF`        = NOW(),
           `USUARIO_MODIF`         = p_USUARIO
     WHERE `SERIE_FAC`  = p_SERIE
       AND `NUMERO_FAC` = p_NUMERO;
    SET p_RESULTADO = 1;
    COMMIT;
  END IF;
END$$
DELIMITER ;
```
Las columnas de las tablas (`OLD.`, `NEW.`) **mantienen su nombre completo con sufijo**, no se pueden renombrar. Si quieres una variable interna del trigger sin sufijo, usa `DECLARE v_<nombre>` y trabaja con ella.

---

## 8. Registrar cambios en el normalizador

Cuando añadas una tabla, una abreviatura o una excepción, **mantén sincronizado** el código del programa `FactuzamNormalizer`. Hay dos formas:

### 8.1 Vía interfaz gráfica (recomendado para cambios puntuales)

1. Abre `FactuzamNormalizer.exe`.
2. Pulsa **Editar configuración…**
3. Añade la fila correspondiente en la pestaña que toque:
   - **Sufijos por tabla** → para una tabla nueva.
   - **Abreviaturas** → si introduces una nueva forma corta a expandir.
   - **Excepciones** → si una columna concreta de una tabla no sigue las reglas estándar.
4. Pulsa **Aceptar**.

Estos cambios solo afectan a la sesión actual. Para que sean permanentes, registra también el cambio en código (siguiente sección).

### 8.2 Vía código (cambio permanente)

Edita `UNormalizerEngine.pas` → método `InitDefaults`. Añade tu entrada al bloque correspondiente.

```pascal
// Sufijo nuevo
AddSuf('fza_promociones', 'PROMO');

// Concepto propio que se debe barrer si aparece en columnas de la tabla
AddOwn('fza_promociones', ['PROMOCION']);

// Abreviatura nueva (siempre que la corta no debe persistir)
FAbbreviations.Add(TKVPair.Create('PROMOC', 'PROMOCION'));

// Excepción puntual (cuando la regla estándar no produce el nombre deseado)
AddException('fza_promociones', 'CODIGO_FAMILIA_PROMOCION', 'CODIGO_FAM_PROMO');
```

Compila el normalizador y, a partir de ese momento, generará los SQL respetando la convención también para la tabla nueva.

---

## 9. Clean SQL y calidad P5

Estas reglas se aplican a scripts de migración, consultas de aplicación,
vistas y procedimientos. Los límites históricos no justifican código nuevo
difícil de leer o de probar.

### 9.1 Legibilidad y nivel de abstracción

- Palabras reservadas SQL en mayúsculas e identificadores con el formato de
  este libro.
- Una columna por línea en listas largas de `SELECT`, `INSERT` y `UPDATE`.
- Cada `JOIN`, `WHERE`, `GROUP BY`, `HAVING` y `ORDER BY` empieza en una
  línea reconocible.
- Todas las columnas de consultas con varias tablas llevan alias de tabla.
- No se usa `SELECT *` en código de producción. Se enumeran las columnas que
  forman el contrato del consumidor.
- Un alias expresa el rol de la tabla y se mantiene en toda la sentencia.
- Un comentario explica la razón, la compatibilidad o el riesgo; no traduce
  una sentencia evidente ni conserva SQL comentado.
- No se dejan líneas en blanco dentro de un bloque SQL ejecutable.

Una consulta responde a una pregunta. Si materializa datos, calcula reglas y
formatea una salida a la vez, se divide en pasos con nombres y contratos
verificables.

### 9.2 Tamaño y complejidad

- Un procedimiento nuevo tiene un único caso de uso y busca permanecer por
  debajo de 80 líneas efectivas.
- Por encima de 120 líneas se divide en procedimientos o pasos cohesivos.
- No se crea ni amplía un procedimiento de más de 200 líneas.
- La anidación máxima habitual es de dos niveles.
- Un procedimiento fiscal, de caja o transaccional no supera 10 decisiones
  sin una justificación documentada y pruebas específicas.
- Una migración puede ser larga por contener comprobaciones repetidas, pero
  cada fichero cubre un único cambio desplegable y verificable.

Las líneas efectivas excluyen comentarios y delimitadores. Los límites son
criterios de revisión aunque todavía no exista un comprobador automático para
todos ellos.

### 9.3 Seguridad de datos y transacciones

- `INSERT`, `UPDATE` y `DELETE` reciben valores mediante parámetros desde
  Delphi. No se concatenan valores de usuario, rutas, códigos ni fechas.
- Los identificadores dinámicos proceden de una lista blanca y se delimitan.
- Todo `UPDATE` o `DELETE` lleva un predicado explícito. Una operación sobre
  toda la tabla exige comentario de intención, copia de seguridad y
  verificación previa del número de filas.
- Una operación que escribe en varias tablas define un único propietario de
  la transacción y garantiza `COMMIT` o `ROLLBACK`.
- Un procedimiento llamado dentro de una transacción no ejecuta un `COMMIT`
  oculto salvo que su contrato declare que es el propietario.
- El DDL de MariaDB puede realizar commits implícitos. Una migración no
  promete rollback transaccional cuando el motor no puede ofrecerlo; incluye
  comprobaciones previas, verificación posterior y rollback compensatorio.
- Los procesos reintentables usan claves, estados o marcas que aseguran
  idempotencia y evitan duplicar documentos, movimientos o eventos fiscales.
- Un cambio destructivo (`DROP`, `RENAME`, reducción de tipo o borrado
  masivo) requiere confirmación del usuario y un rollback preparado.

### 9.4 Rendimiento observable

- Los filtros, uniones y ordenaciones frecuentes tienen un índice justificable
  por el patrón real de acceso; no se crean índices por intuición.
- Se revisa `EXPLAIN` al añadir o modificar consultas sobre tablas de gran
  volumen o caminos interactivos sensibles.
- Se evitan funciones sobre columnas indexadas dentro de predicados cuando
  impidan usar el índice.
- Para comprobar existencia se prefiere `EXISTS` o `LIMIT 1`; no se cuentan
  todas las filas si el total no forma parte del resultado.
- No se introduce una consulta por fila cuando el mismo trabajo puede
  resolverse por conjuntos.
- La optimización conserva primero la corrección. Toda reescritura de SQL
  mantiene pruebas de resultados y casos límite.

### 9.5 Errores, contratos y pruebas

- Un procedimiento devuelve estados mediante códigos o resultados definidos;
  no obliga al consumidor a interpretar texto libre.
- Un error SQL no se convierte en éxito ni se silencia. El handler revierte
  lo que posee y usa `RESIGNAL` cuando el llamador debe conocer el fallo.
- Los `NULL`, cadenas vacías y valores `'S'`/`'N'` tienen una semántica
  explícita y coherente con el contrato Delphi.
- Las columnas devueltas por una vista o procedimiento constituyen un
  contrato: se enumeran, se nombran de forma estable y se prueban.
- Toda migración se ejecuta al menos dos veces sobre una BBDD de prueba para
  demostrar idempotencia.
- Las pruebas cubren datos existentes, ausencia de datos, límites, error y
  rollback. Los cambios fiscales o de caja incluyen además reintento y
  prevención de duplicados.

---

## 10. Lista de verificación antes de hacer commit

Antes de subir un cambio que toque el esquema, verifica:

- `factuzam_original.sql` no se ha modificado.
- El cambio vive en un script idempotente de `DESARROLLOS EN CURSO/` y se ha
  ejecutado dos veces sobre una BBDD de prueba.
- La tabla nueva (si la hay) está en el catálogo de la sección 2.
- Todas las columnas terminan con el sufijo correcto, salvo las cuatro de auditoría.
- Las FK lógicas siguen el patrón `<TIPO_ID>_<SUFIJO_DESTINO>_<SUFIJO_TABLA>`.
- Los booleanos llevan prefijo `ES` sin guion bajo.
- No has introducido ninguna abreviatura prohibida (`NRO`, `CPOSTAL`, `PORCEN`, `FORMAP`, `RAZONSOCIAL`).
- Los índices se llaman `IDX_<SUF>_…` o `UQ_<SUF>_…`.
- Las vistas empiezan por `VI_`, los procedimientos por `PRC_`, las funciones por `FN_`, los triggers por `TRG_`.
- Has registrado los cambios estructurales (sufijo nuevo, abreviatura nueva, excepción) en `UNormalizerEngine.pas`.
- No hay `SELECT *`, valores externos concatenados ni SQL dinámico sin lista
  blanca.
- Las escrituras múltiples tienen propietario de transacción, `COMMIT`,
  `ROLLBACK` y pruebas de error.
- Los `UPDATE` y `DELETE` incluyen un predicado explícito; los masivos tienen
  confirmación, estimación de filas y rollback.
- Los procedimientos nuevos permanecen por debajo de 80 líneas efectivas y
  las zonas fiscales, de caja o transaccionales no superan 10 decisiones.
- Las consultas sensibles se han revisado con `EXPLAIN` y sus índices están
  justificados por filtros, uniones u ordenaciones reales.
- Los contratos de vistas y procedimientos enumeran columnas y representan
  estados mediante tipos o códigos, no mediante interpretación de mensajes.
- Los scripts conservan UTF-8, finales CRLF y no contienen líneas en blanco
  dentro de bloques SQL ejecutables.
