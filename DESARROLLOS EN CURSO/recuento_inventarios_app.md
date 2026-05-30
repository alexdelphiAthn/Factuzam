# Recuento de inventarios con app Android (diseño)

Subsistema para recontar inventarios físicos con una app de mano, usando un
servidor REST (PHP + MySQL) como **puente** entre Factuzam y los terminales.

> Estado: **DISEÑO para revisar**. Nada aplicado, nada commiteado. Las DDL de
> este documento son borradores; cuando demos el visto bueno se sacan a
> scripts idempotentes en `DESARROLLOS EN CURSO/` (Factuzam) y a un `.sql`
> aparte para el servidor. `factuzam_original.sql` NO se toca.

---

## 1. Objetivo

1. Desde Factuzam (`inMtoInventarios`) se **envía** un inventario a recontar al
   servidor.
2. La **app Android** se descarga la tarea y su catálogo, y **recuenta**
   escaneando códigos de barras (uno o varios operarios a la vez).
3. Cada escaneo es un **evento con su día/hora** (la "unidad de recuento").
4. La app **sube** los eventos al servidor (offline-first, por lotes).
5. Factuzam **recoge** el recuento, rellena `CANTIDAD_FISICA_INVLIN` y guarda
   el detalle escaneo a escaneo. A partir de ahí, el flujo de regularización
   de stock que YA existe (`APLICAR`) no cambia.

## 2. Decisiones ya tomadas

| Tema | Decisión |
|---|---|
| Plataforma de la app | **Android nativo en Delphi FMX** (offline + escáner) |
| Modelo de recuento | **Evento por escaneo**, multi-operario, se agrega por SKU |
| Traza en Factuzam | **Opción B**: tabla `fza_inventarios_recuentos` (INVREC) con cada escaneo |
| Servidor | **Mismo host que las fotos (DreamHost)**, BBDD MySQL nueva |
| Auth Factuzam ↔ servidor | `X-API-Key` (igual que fotos) |
| Auth app ↔ servidor | **token por dispositivo** + `carpeta_cliente` |
| Acceso a datos (cliente y app) | **UniDAC** (en la app, provider SQLite local) |
| HTTP / JSON | `System.Net.HttpClient` + `System.JSON` (igual que `inLibFotosNube`) |

## 3. Arquitectura (3 capas)

```
   ON-PREMISE (tienda/oficina)                    NUBE (DreamHost)
 ┌──────────────────────────────┐         ┌──────────────────────────────┐
 │  Factuzam VCL  ───────────────┼──HTTPS──┼─▶  API REST PHP               │
 │   inMtoInventarios            │ X-API-Key│    inv_*.php                  │
 │   inLibInventarioNube (nuevo) │◀─────────┼──  + MySQL "puente"          │
 │        │                      │         │       inv_tareas              │
 │        ▼ UniDAC               │         │       inv_catalogo            │
 │   MariaDB Factuzam            │         │       inv_eventos             │
 │   fza_inventarios / _lineas   │         └───────────▲──────────────────┘
 │   fza_inventarios_recuentos   │                     │ HTTPS, token disp.
 │        (nueva tabla)          │                     │
 └──────────────────────────────┘         ┌───────────┴──────────────────┐
                                          │  App Android FMX             │
                                          │   SQLite local (cola offline)│
                                          │   escaneo → eventos          │
                                          └──────────────────────────────┘
```

El servidor es **un buzón/puente**, no una réplica de Factuzam. Solo guarda
tareas de recuento, su catálogo y los eventos de escaneo. La verdad del stock
sigue en la MariaDB de Factuzam.

## 4. Qué se reutiliza (no se reinventa)

- **Tablas que ya existen**: `fza_inventarios` (INV) y `fza_inventarios_lineas`
  (INVLIN). INVLIN ya tiene `CANTIDAD_TEORICA_INVLIN`, `CANTIDAD_FISICA_INVLIN`,
  `CANTIDAD_DIFERENCIA_INVLIN` y `FECHA_RECUENTO_INVLIN`.
- **Camino de importar conteos**: hoy `inLibInventarioExcel` →
  `TdmInventarios.CargarDesdeListaSkus` escribe `CANTIDAD_FISICA`. El
  "recoger del servidor" se engancha en el mismo sitio.
- **Resolución de escaneo**: `inMtoInventarios.ResolverInputArticulo` ya casa
  código de artículo / SKU / **código de barras** (`fza_codigos_barras`).
- **Patrón nube**: `inLibFotosNube` (THTTPClient + JSON + `oAppParams`) y el
  contrato PHP de `download_foto.php` (`X-API-Key`, `carpeta_cliente`,
  errores `{ "message": "..." }`). Se calca tal cual.
- **Regularización**: `PRC_FZA_INVENTARIOS_APLICAR` y los movimientos de
  almacén NO se tocan. El recuento remoto solo rellena las físicas.

### 4.1 El web service ES el Excel, pero por HTTP

El paralelismo es 1:1 con `inLibInventarioExcel`. Misma idea, mismo destino en
Factuzam; sólo cambia el transporte (HTTP en vez de fichero) y el "papel"
(la app en vez de rellenar la hoja a mano):

| Hoy (Excel, fichero) | Con la app (servicio web) |
|---|---|
| `ExportarInventarioExcel` (cabecera + líneas → .xlsx) | `EnviarInventario` → `POST inv_enviar.php` (mismas columnas en JSON) |
| El operario teclea "Uds. Físicas" en el Excel | El operario escanea en la app |
| `ImportarInventarioDesdeSheet` → lista `SKU=CANTIDAD` (+ PMP nuevo) | `RecogerRecuento` → `GET inv_recoger.php` → misma lista `SKU=CANTIDAD` |
| `CargarDesdeListaSkus` escribe `CANTIDAD_FISICA_INVLIN` | **el MISMO** `CargarDesdeListaSkus` |

O sea: en Factuzam, "recoger" reutiliza **exactamente** la tubería del import de
Excel. Lo único que la app añade sobre el Excel es que **cada lectura lleva su
día/hora**; el servidor las consolida a `SKU=CANTIDAD`, que es justo lo que
Factuzam ya sabe ingerir. Esa diferencia es la que decide A vs B en §5.2.

## 5. Modelo de datos

### 5.1 Servidor puente (MySQL en DreamHost)

BBDD independiente (p.ej. `factuzam_recuentos`). Es PHP-propia, **no** sigue el
sufijo `fza_`/`_TABLA` del libro de estilo (ese gobierna la MariaDB de
Factuzam). Convención propia: `inv_` + snake_case.

```sql
-- Una tarea = un inventario enviado a recontar.
CREATE TABLE inv_tareas (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  carpeta_cliente   VARCHAR(80)  NOT NULL,          -- tenant (igual que fotos)
  codigo_emp        VARCHAR(10)  NOT NULL,          -- clave del fza_inventarios
  codigo_alm        VARCHAR(10)  NOT NULL,
  serie             VARCHAR(20)  NOT NULL,
  numero            VARCHAR(20)  NOT NULL,
  descripcion       VARCHAR(200) NULL,
  modo              ENUM('DIRIGIDO','CIEGO') NOT NULL DEFAULT 'DIRIGIDO',
  estado            ENUM('PENDIENTE','EN_RECUENTO','RECONTADO',
                         'RECOGIDO','CANCELADO') NOT NULL DEFAULT 'PENDIENTE',
  instante_envio    DATETIME NOT NULL,
  instante_recogida DATETIME NULL,
  usuario_envio     VARCHAR(100) NULL,
  instante_alta     DATETIME NOT NULL,
  instante_modif    DATETIME NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tarea (carpeta_cliente, codigo_emp, codigo_alm, serie, numero),
  KEY idx_tarea_estado (carpeta_cliente, estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Catálogo que necesita la app para resolver escaneos offline y dar feedback.
-- En modo CIEGO puede ser todo el catálogo del almacén; en DIRIGIDO, sólo los
-- SKUs a contar. Un SKU puede tener varios códigos de barras.
CREATE TABLE inv_catalogo (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_tarea        BIGINT UNSIGNED NOT NULL,
  codigo_articulo VARCHAR(20)  NOT NULL,
  codigo_unidad   VARCHAR(50)  NOT NULL,            -- SKU
  descripcion     VARCHAR(200) NULL,
  codigo_barras   VARCHAR(50)  NULL,                -- una fila por código
  cantidad_teorica DECIMAL(19,6) NULL,             -- NULL si recuento ciego
  PRIMARY KEY (id),
  KEY idx_cat_tarea (id_tarea),
  KEY idx_cat_barras (id_tarea, codigo_barras),
  KEY idx_cat_sku (id_tarea, codigo_unidad)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- El corazón del "evento por escaneo". Una fila por lectura.
CREATE TABLE inv_eventos (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_tarea          BIGINT UNSIGNED NOT NULL,
  uuid_evento       CHAR(36) NOT NULL,             -- idempotencia (lo crea la app)
  codigo_barras     VARCHAR(50) NULL,              -- código crudo leído
  codigo_articulo   VARCHAR(20) NULL,              -- resuelto por la app (o NULL)
  codigo_unidad     VARCHAR(50) NULL,              -- SKU resuelto (o NULL)
  cantidad          DECIMAL(19,6) NOT NULL DEFAULT 1,
  lote              VARCHAR(50) NULL,
  fecha_caducidad   DATE NULL,
  instante_recuento DATETIME NOT NULL,             -- día/hora de ESTA unidad
  operario          VARCHAR(100) NULL,             -- quién contó
  dispositivo       VARCHAR(100) NULL,             -- terminal
  zona              VARCHAR(100) NULL,             -- pasillo/ubicación (opcional)
  anulado           CHAR(1) NOT NULL DEFAULT 'N',  -- corregir una lectura mala
  instante_recibido DATETIME NOT NULL,             -- hora servidor (clock-skew)
  PRIMARY KEY (id),
  UNIQUE KEY uq_evento_uuid (uuid_evento),
  KEY idx_evt_tarea (id_tarea, id),                -- cursor incremental
  KEY idx_evt_sku (id_tarea, codigo_unidad)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Dispositivos/operarios dados de alta, con su token de acceso.
CREATE TABLE inv_dispositivos (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  carpeta_cliente VARCHAR(80)  NOT NULL,
  nombre          VARCHAR(100) NOT NULL,
  operario        VARCHAR(100) NULL,
  token           CHAR(64) NOT NULL,
  esactivo        CHAR(1) NOT NULL DEFAULT 'S',
  instante_alta   DATETIME NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_disp_token (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 5.2 Factuzam (MariaDB) — cambios de esquema

**Elegida la Opción B.** Además de meter `SKU=CANTIDAD` por
`CargarDesdeListaSkus` (igual que el Excel), se guarda **cada escaneo** en una
tabla nueva `fza_inventarios_recuentos`, para poder revisar más adelante el
origen del recuento: qué código leyó el móvil, cuándo, quién y con qué terminal.
(La alternativa A —sin tablas nuevas, solo el consolidado— queda descartada.)

Cambios idempotentes, en `DESARROLLOS EN CURSO/`. **No** se toca
`factuzam_original.sql`.

**Nueva tabla `fza_inventarios_recuentos` (sufijo `INVREC`)** — una fila por
escaneo. `CANTIDAD_FISICA_INVLIN` = **suma** de los INVREC de ese SKU; cada
evento conserva su día/hora, operario, terminal y el código de barras crudo
leído.

```sql
CREATE TABLE `fza_inventarios_recuentos` (
  `ID_INVREC`               bigint        NOT NULL AUTO_INCREMENT,
  `UUID_INVREC`             varchar(36)   NOT NULL,
  `CODIGO_EMP_INVREC`       varchar(10)   NOT NULL,
  `CODIGO_ALM_INVREC`       varchar(10)   NOT NULL,
  `SERIE_INV_INVREC`        varchar(20)   NOT NULL,
  `NUMERO_INV_INVREC`       varchar(20)   NOT NULL,
  `CODIGO_ART_INVREC`       varchar(20)   DEFAULT NULL,
  `CODIGO_UNIDAD_INVREC`    varchar(50)   DEFAULT NULL,
  `CODIGO_BARRAS_INVREC`    varchar(50)   DEFAULT NULL,
  `CANTIDAD_INVREC`         decimal(19,6) NOT NULL DEFAULT 1.000000,
  `LOTE_INVREC`             varchar(50)   DEFAULT '',
  `FECHA_CADUCIDAD_INVREC`  date          DEFAULT NULL,
  `INSTANTE_RECUENTO_INVREC` datetime     NOT NULL,
  `OPERARIO_INVREC`         varchar(100)  DEFAULT NULL,
  `DISPOSITIVO_INVREC`      varchar(100)  DEFAULT NULL,
  `ZONA_INVREC`             varchar(100)  DEFAULT NULL,
  `ESANULADO_INVREC`        char(1)       NOT NULL DEFAULT 'N',
  `INSTANTE_ALTA`           datetime      NOT NULL,
  `USUARIO_ALTA`            varchar(100)  NOT NULL,
  `INSTANTE_MODIF`          datetime      DEFAULT NULL,
  `USUARIO_MODIF`           varchar(100)  DEFAULT NULL,
  PRIMARY KEY (`ID_INVREC`),
  UNIQUE KEY `UQ_INVREC_UUID` (`UUID_INVREC`),
  KEY `IDX_INVREC_DOC` (`CODIGO_EMP_INVREC`,`CODIGO_ALM_INVREC`,
                        `SERIE_INV_INVREC`,`NUMERO_INV_INVREC`),
  KEY `IDX_INVREC_UNIDAD` (`CODIGO_UNIDAD_INVREC`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

Notas de estilo: `INSTANTE_RECUENTO_INVREC` lleva prefijo `INSTANTE_` por ser
`datetime` (en INVLIN se llama `FECHA_RECUENTO_INVLIN`, nombre legacy). FKs
lógicas con el patrón de INVLIN (`SERIE_INV_INVREC`, `NUMERO_INV_INVREC`,
`CODIGO_UNIDAD_INVREC`). Booleano `ESANULADO_INVREC`. Auditoría sin sufijo.
Hay que **registrar el sufijo `INVREC`** en `UNormalizerEngine.pas` y en el
catálogo del libro de estilo BBDD §2.

**Marcadores de ciclo en `fza_inventarios`** (ligero, útil en A y B; ALTER
idempotente):

```sql
ESRECUENTO_REMOTO_INV            char(1)  NOT NULL DEFAULT 'N'  -- enviado a la app
INSTANTE_ENVIO_RECUENTO_INV      datetime DEFAULT NULL
INSTANTE_RECOGIDA_RECUENTO_INV   datetime DEFAULT NULL
ID_TAREA_REMOTA_INV              varchar(40) DEFAULT NULL       -- id en el puente
```

`ESTADO_INV` se queda `ABIERTO` mientras el inventario está fuera contándose;
al recoger, se rellenan físicas y el usuario revisa y **APLICA** como hoy. Así
el flujo de regularización existente no cambia.

## 6. Contrato REST (PHP)

Mismo estilo "script plano" del servidor de fotos (DreamHost compartido).
Todo JSON; errores `{ "message": "..." }` + status HTTP correcto. HTTPS
obligatorio.

**Factuzam ↔ servidor** (cabecera `X-API-Key`):

| Método y script | Para qué |
|---|---|
| `POST inv_enviar.php` | Crea/reemplaza una tarea + su catálogo. Idempotente por (carpeta, emp, alm, serie, numero). |
| `GET  inv_estado.php?...` | Estado + progreso (nº eventos, nº SKUs, último escaneo). |
| `GET  inv_recoger.php?...&desde=<id>` | Devuelve eventos (crudo) y/o agregado por SKU. Cursor incremental. Marca `RECOGIDO` al cerrar. |

**App ↔ servidor** (cabecera token de dispositivo + `carpeta_cliente`):

| Método y script | Para qué |
|---|---|
| `POST disp_registrar.php` | Alta de dispositivo, devuelve token. |
| `GET  inv_tareas.php` | Lista de tareas `PENDIENTE`/`EN_RECUENTO` del tenant. |
| `GET  inv_catalogo.php?id_tarea=..&desde=..` | Catálogo paginado. |
| `POST inv_eventos.php` | Sube un lote de eventos. Idempotente por `uuid_evento`. Devuelve aceptados/duplicados. |
| `POST inv_finalizar.php` | Marca la tarea `RECONTADO`. |

Ejemplo de lote de eventos (`POST inv_eventos.php`):

```json
{ "id_tarea": 42, "dispositivo": "PDA-03", "operario": "MARTA",
  "eventos": [
    { "uuid": "f1c2...-...", "codigo_barras": "8412345000123",
      "codigo_unidad": "CAMISA/AZUL/M", "cantidad": 1,
      "instante_recuento": "2026-05-30T11:42:07" }
  ] }
```

## 7. App Android (Delphi FMX)

- **Stack**: FMX + UniDAC (provider **SQLite** local para la cola offline) +
  `System.Net.HttpClient` + `System.JSON`. Misma familia que Factuzam; sin
  meter FireDAC.
- **Offline-first**: todo escaneo se inserta primero en SQLite local
  (con su `uuid` y su `instante_recuento` del reloj del terminal). La subida es
  un proceso aparte que vacía la cola por lotes; reintenta con backoff. Como el
  servidor deduplica por `uuid`, reenviar un lote no duplica.
- **Escaneo** (dos vías, sin dependencia nueva pesada de inicio):
  1. **Lector hardware (keyboard-wedge / intent)**: los terminales de almacén
     (Zebra/Honeywell) emiten el código como texto a un campo con foco. Cero
     librerías. **Vía recomendada para arrancar.**
  2. **Cámara**: requiere un componente de decodificación de barras (ZXing
     port o comercial). Se deja como ampliación para no añadir dependencia
     ahora (regla "no deps nuevas sin justificación").
- **Flujo**: login/registro de dispositivo → elegir tarea → descargar catálogo
  → contar (escaneo = +1, cantidad editable; feedback con descripción del SKU;
  si el código no está en catálogo, se guarda crudo como "no identificado") →
  sincronizar (manual o automático) → finalizar.
- **Multi-operario**: varios terminales contra la misma tarea. El servidor
  acumula todos los eventos; el SKU se agrega sumando.

## 8. Integración en Factuzam (VCL)

- **Nueva unit `inLibInventarioNube.pas`** (en `src/Lib/`), gemela de
  `inLibFotosNube`: `EnviarInventario`, `ConsultarEstado`, `RecogerRecuento`.
  THTTPClient + JSON. Config en `oAppParams` (categoría nueva "Recuentos":
  `appRecuentoUrl`, `appRecuentoApiKey`, `appRecuentoCarpetaCliente`).
- **Dos botones en `inMtoInventarios`** (junto a `btnExportarInv` /
  `btnCargarExcel`), preferentemente `TcxButton`:
  - **"Enviar a recuento"**: arma el catálogo del inventario actual (SKUs de las
    líneas + sus códigos de barras de `fza_codigos_barras` + descripción +
    teórica de `fza_articulos_stockactual`; en modo ciego, el catálogo del
    almacén) y hace `POST inv_enviar.php`. Marca `ESRECUENTO_REMOTO_INV='S'`.
  - **"Recoger recuento"**: `GET inv_recoger.php`, inserta los eventos en
    `fza_inventarios_recuentos`, recalcula `CANTIDAD_FISICA_INVLIN` = suma por
    SKU (creando la línea si el SKU es nuevo, reutilizando
    `CargarDesdeListaSkus`) y pone `FECHA_RECUENTO_INVLIN` = último escaneo.
    Luego el usuario revisa y **APLICA** con el flujo actual.
- **Pumpear versión** en `inLibGlobalVar.pas` al implementar (regla repo §6).

## 9. Ciclo de vida

```
Factuzam: inventario ABIERTO
   │  "Enviar a recuento"
   ▼
Servidor: tarea PENDIENTE ──app descarga──▶ EN_RECUENTO ──escaneos──▶ ...
   │                                                  │ "Finalizar"
   │                                                  ▼
   │                                            RECONTADO
   │  "Recoger recuento" (Factuzam)                   │
   ▼                                                  ▼
Factuzam: rellena físicas + INVREC            Servidor: RECOGIDO
   │  (usuario revisa)
   ▼
APLICAR  →  regularización de stock (flujo actual, sin cambios)
```

## 10. Seguridad

- HTTPS siempre (Let's Encrypt en DreamHost).
- Factuzam ↔ servidor: `X-API-Key` (servidor a servidor, de confianza).
- App ↔ servidor: **token por dispositivo** (no se reparte la API key maestra a
  los móviles) + `carpeta_cliente` para aislar tenant. Token revocable
  (`esactivo='N'`).
- Límite de tamaño de lote y validación de payload (hosting compartido).

## 11. Idempotencia y sincronización

- **Eventos**: `uuid_evento` único en servidor → reenvíos no duplican. La app
  marca el evento como "subido" sólo tras 200 OK.
- **Recogida en Factuzam**: `UUID_INVREC` único → recoger dos veces no duplica
  filas; se hace `INSERT ... ON DUPLICATE KEY` / comprobación previa.
- **Cursor incremental**: `inv_recoger.php?desde=<id>` y
  `inv_catalogo.php?desde=<id>` permiten traer sólo lo nuevo.

## 12. Fases de entrega (propuesta)

1. **Esquema**: scripts idempotentes Factuzam (INVREC + ALTERs) + `.sql` del
   servidor puente. Registrar `INVREC` en el normalizador y libro de estilo.
2. **Servidor PHP**: endpoints + auth, sobre la BBDD nueva en DreamHost.
3. **Factuzam VCL**: `inLibInventarioNube` + los 2 botones en `inMtoInventarios`.
4. **App Android FMX**: login, descarga de tarea/catálogo, escaneo
   (keyboard-wedge), cola SQLite, sync, finalizar.
5. **Ampliaciones**: escaneo por cámara, zonas/ubicaciones, panel de progreso
   en vivo en Factuzam, recuento ciego de almacén completo.

## 13. Decisiones abiertas (para verlo juntos)

1. ✅ **DECIDIDO — Opción B**: se guarda cada escaneo en
   `fza_inventarios_recuentos` (sufijo `INVREC`, a registrar en el normalizador y
   en el libro de estilo BBDD §2) para revisar el origen del recuento.
2. **Modo por defecto**: ¿dirigido (lista de SKUs) o ciego (todo el almacén)?
3. **¿Una BBDD nueva** `factuzam_recuentos` en DreamHost, o tablas `inv_*`
   dentro de la BBDD que ya usa el servidor de fotos?
4. **Cantidad por escaneo**: ¿siempre +1, o permitir teclear cantidad (cajas)?
5. **Lote/caducidad**: ¿la app los pide para artículos trazables
   (`ESTRAZABLE_ART='S'`) o se ignoran de momento?
6. **Cierre de tarea**: ¿lo finaliza cualquier operario, o sólo un supervisor?

## 14. Reglas del repo respetadas

- `factuzam_original.sql` intacto; cambios de esquema idempotentes en
  `DESARROLLOS EN CURSO/`.
- Sufijo nuevo `INVREC` siguiendo el libro de estilo BBDD (a registrar).
- Español en código/comentarios; UniDAC; THTTPClient+JSON como el resto.
- Sin dependencias nuevas en el arranque (escaneo por keyboard-wedge).
- Nada commiteado hasta que lo aprobemos; versión a pumpear al implementar.
