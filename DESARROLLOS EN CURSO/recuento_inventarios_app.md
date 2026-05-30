# Recuento de inventarios con app Android (diseño)

Subsistema para recontar inventarios físicos con una app de mano, usando un
servidor REST (PHP + MySQL) como **puente** entre Factuzam y los terminales.

> Estado: **DISEÑO para revisar**. Ficheros de este desarrollo:
> - `recuento_inventarios_app.md` — este documento (diseño general).
> - `recuento_inventarios_factuzam.sql` — DDL idempotente de Factuzam (INVREC +
>   marcadores en `fza_inventarios`). `factuzam_original.sql` NO se toca.
> - `recuento_inventarios_servidor.sql` — DDL de la BBDD MySQL del servidor.
> - `recuento_inventarios_php.md` — contrato REST + esqueletos PHP.

---

## 1. Objetivo

1. Desde Factuzam (`inMtoInventarios`) se **envía** un inventario a recontar al
   servidor (una "plantilla").
2. La **app Android** recoge la plantilla (o cuenta libre por almacén) y
   **recuenta** escaneando códigos de barras (uno o varios operarios a la vez).
3. Cada escaneo es un **evento con su día/hora** (la "unidad de recuento").
4. Al terminar, la app **sube** el recuento al servidor (offline-first, lotes).
5. Factuzam **recoge** el recuento, rellena `CANTIDAD_FISICA_INVLIN` y guarda
   el detalle escaneo a escaneo (INVREC). A partir de ahí, el flujo de
   regularización de stock que YA existe (`APLICAR`) no cambia.

## 2. Decisiones ya tomadas

| Tema | Decisión |
|---|---|
| Plataforma de la app | **Android nativo en Delphi FMX** (offline + escáner) |
| Modelo de recuento | **Evento por escaneo**, multi-operario, se agrega por SKU |
| Traza en Factuzam | **Opción B**: tabla `fza_inventarios_recuentos` (INVREC) con cada escaneo |
| App: menú | (1) escanear =+1 · (2) escanear + cantidad · (3) recoger plantilla |
| Opciones 1 y 2 | **recuento libre**: preguntan el **almacén** (no exigen plantilla) |
| Opción 3 | **exige plantilla previa** (la que Factuzam envió) |
| Al finalizar | la app **sube el recuento al webservice** y lo marca `RECONTADO` |
| Lote/caducidad | Solo en artículos trazables (`ESTRAZABLE_ART='S'`) |
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
 │        │                      │         │       inv_recuentos           │
 │        ▼ UniDAC               │         │       inv_catalogo / eventos  │
 │   MariaDB Factuzam            │         │       inv_almacenes           │
 │   fza_inventarios / _lineas   │         └───────────▲──────────────────┘
 │   fza_inventarios_recuentos   │                     │ HTTPS, token disp.
 │        (tabla INVREC)         │                     │
 └──────────────────────────────┘         ┌───────────┴──────────────────┐
                                          │  App Android FMX             │
                                          │   SQLite local (cola offline)│
                                          │   escaneo → eventos          │
                                          └──────────────────────────────┘
```

El servidor es **un buzón/puente**, no una réplica de Factuzam. Solo guarda
recuentos, su catálogo y los eventos de escaneo. La verdad del stock sigue en
la MariaDB de Factuzam.

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
| `ImportarInventarioDesdeSheet` → lista `SKU=CANTIDAD` | `RecogerRecuento` → `GET inv_recoger.php` → mismo `SKU=CANTIDAD` (campo `agregado`) |
| `CargarDesdeListaSkus` escribe `CANTIDAD_FISICA_INVLIN` | **el MISMO** `CargarDesdeListaSkus` |

En Factuzam, "recoger" reutiliza **exactamente** la tubería del import de Excel.
Lo único que la app añade sobre el Excel es que **cada lectura lleva su
día/hora**; el servidor las consolida a `SKU=CANTIDAD` (eso es lo que Factuzam
ingiere) y, además, guardamos el detalle por lectura en INVREC (Opción B).

## 5. Modelo de datos

### 5.1 Servidor puente (MySQL en DreamHost)

BBDD independiente (p.ej. `factuzam_recuentos`). Es PHP-propia, **no** sigue el
sufijo `fza_`/`_TABLA` del libro de estilo. Convención propia: `inv_` +
snake_case. **DDL completa y runnable en `recuento_inventarios_servidor.sql`.**

| Tabla | Para qué |
|---|---|
| `inv_recuentos` | Cabecera de sesión. `origen` = FACTUZAM (plantilla, `modo`=DIRIGIDO) o APP (recuento LIBRE de un almacén). |
| `inv_catalogo` | Líneas de la plantilla (solo DIRIGIDO): SKU, código de barras, descripción, teórica, trazable. |
| `inv_eventos` | El "evento por escaneo": una fila por lectura, con su día/hora. Idempotente por `uuid_evento`. |
| `inv_almacenes` | Lista de almacenes que Factuzam sincroniza, para el selector de almacén del recuento libre. |
| `inv_dispositivos` | Terminales/operarios con su token de acceso. |

### 5.2 Factuzam (MariaDB) — cambios de esquema

**Opción B**: además de meter `SKU=CANTIDAD` por `CargarDesdeListaSkus` (igual
que el Excel), se guarda **cada escaneo** en `fza_inventarios_recuentos`, para
revisar el origen del recuento (qué leyó el móvil, cuándo, quién, qué terminal).
Idempotente, en `recuento_inventarios_factuzam.sql`. **No** se toca
`factuzam_original.sql`.

**Tabla `fza_inventarios_recuentos` (sufijo `INVREC`)** — una fila por escaneo.
La **PK es la misma clave del inventario** (empresa+almacén+serie+número) **+
`UUID_INVREC`** como discriminador de cada lectura — el mismo patrón que
`fza_inventarios_lineas` (que añade `LINEA_INVLIN` a esas 4 columnas). **Sin
contador autoincremental**: el `UUID` (lo crea la app) ya identifica de forma
única el escaneo y da idempotencia al recoger.

```sql
CREATE TABLE `fza_inventarios_recuentos` (
  `CODIGO_EMP_INVREC`        varchar(10)   NOT NULL,
  `CODIGO_ALM_INVREC`        varchar(10)   NOT NULL,
  `SERIE_INV_INVREC`         varchar(20)   NOT NULL,
  `NUMERO_INV_INVREC`        varchar(20)   NOT NULL,
  `UUID_INVREC`              varchar(36)   NOT NULL,
  `CODIGO_ART_INVREC`        varchar(20)   DEFAULT NULL,
  `CODIGO_UNIDAD_INVREC`     varchar(50)   DEFAULT NULL,
  `CODIGO_BARRAS_INVREC`     varchar(50)   DEFAULT NULL,
  `CANTIDAD_INVREC`          decimal(19,6) NOT NULL DEFAULT 1.000000,
  `LOTE_INVREC`              varchar(50)   DEFAULT '',
  `FECHA_CADUCIDAD_INVREC`   date          DEFAULT NULL,
  `INSTANTE_RECUENTO_INVREC` datetime      NOT NULL,
  `OPERARIO_INVREC`          varchar(100)  DEFAULT NULL,
  `DISPOSITIVO_INVREC`       varchar(100)  DEFAULT NULL,
  `ZONA_INVREC`              varchar(100)  DEFAULT NULL,
  `ESANULADO_INVREC`         char(1)       NOT NULL DEFAULT 'N',
  `INSTANTE_ALTA`            datetime      NOT NULL,
  `USUARIO_ALTA`             varchar(100)  NOT NULL,
  `INSTANTE_MODIF`           datetime      DEFAULT NULL,
  `USUARIO_MODIF`            varchar(100)  DEFAULT NULL,
  PRIMARY KEY (`CODIGO_EMP_INVREC`,`CODIGO_ALM_INVREC`,`SERIE_INV_INVREC`,
               `NUMERO_INV_INVREC`,`UUID_INVREC`),
  KEY `IDX_INVREC_UNIDAD` (`CODIGO_UNIDAD_INVREC`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

Estilo: `INSTANTE_RECUENTO_INVREC` lleva prefijo `INSTANTE_` por ser `datetime`
(en INVLIN se llama `FECHA_RECUENTO_INVLIN`, nombre legacy). FKs lógicas con el
patrón de INVLIN. Booleano `ESANULADO_INVREC`. Auditoría sin sufijo. Hay que
**registrar el sufijo `INVREC`** en `UNormalizerEngine.pas` y en el libro de
estilo BBDD §2.

**Marcadores de ciclo en `fza_inventarios`** (`ADD COLUMN IF NOT EXISTS`):

```sql
ESRECUENTO_REMOTO_INV            char(1)  NOT NULL DEFAULT 'N'  -- enviado a la app
INSTANTE_ENVIO_RECUENTO_INV      datetime DEFAULT NULL
INSTANTE_RECOGIDA_RECUENTO_INV   datetime DEFAULT NULL
ID_RECUENTO_REMOTO_INV           varchar(40) DEFAULT NULL       -- id en el puente
```

`ESTADO_INV` se queda `ABIERTO` mientras el inventario está fuera contándose;
al recoger, se rellenan físicas y el usuario revisa y **APLICA** como hoy.

## 6. Contrato REST

Resumen (detalle + esqueletos PHP en `recuento_inventarios_php.md`). Todo JSON;
errores `{ "message": "..." }` + status HTTP. HTTPS obligatorio.

**App ↔ servidor** (token de dispositivo + `carpeta_cliente`):

| Método · script | Para qué |
|---|---|
| `POST disp_registrar.php` | Alta de dispositivo → token. |
| `GET inv_almacenes.php` | Almacenes para el selector (recuento libre 1/2). |
| `GET inv_recuentos.php` | Plantillas pendientes (opción 3). |
| `POST inv_recuentos.php` | Crea un recuento **libre** de un almacén (1/2). |
| `GET inv_catalogo.php` | Catálogo de la plantilla (paginado). |
| `POST inv_eventos.php` | Sube lote de escaneos. Idempotente por `uuid`. |
| `POST inv_finalizar.php` | Marca el recuento `RECONTADO`. |

**Factuzam ↔ servidor** (`X-API-Key`):

| Método · script | Para qué |
|---|---|
| `POST inv_enviar.php` | Crea/reemplaza plantilla + catálogo. Idempotente por la clave del inventario. |
| `POST inv_almacenes_sync.php` | Sincroniza la lista de almacenes. |
| `GET inv_pendientes.php` | Recuentos `RECONTADO` listos para recoger. |
| `GET inv_recoger.php` | Eventos + `agregado` por SKU. Cursor incremental. Marca `RECOGIDO`. |
| `GET inv_estado.php` | Estado + progreso. |

## 7. App Android (Delphi FMX)

### 7.1 Menú principal (3 opciones)

1. **Recontar códigos de barras** — escaneo rápido, cada lectura suma **+1**.
   No exige plantilla: **pregunta el almacén** (recuento libre) y a contar.
2. **Recontar códigos de barras + cantidad** — igual que 1 pero tras escanear
   se **teclea la cantidad** (cajas/múltiplos). También pregunta el almacén.
3. **Recoger plantilla de recuento** — **exige** que Factuzam haya enviado una
   plantilla: la descarga (SKUs + códigos de barras + descripción + teórica) y
   cuenta contra ella (resuelve descripción/teórica y marca lo no esperado).

Los modos 1 y 2 son la misma pantalla de conteo, cambiando solo si la cantidad
es 1 fija o tecleada; todos generan eventos `inv_eventos` (y, ya en Factuzam,
filas `INVREC`). El almacén del recuento libre sale de `inv_almacenes`.

### 7.2 Stack y mecánica

- **Stack**: FMX + UniDAC (provider **SQLite** local para la cola offline) +
  `System.Net.HttpClient` + `System.JSON`. Misma familia que Factuzam; sin
  meter FireDAC.
- **Offline-first**: todo escaneo se inserta primero en SQLite local (con su
  `uuid` y su `instante_recuento` del reloj del terminal). La subida es un
  proceso aparte que vacía la cola por lotes; reintenta con backoff. Como el
  servidor deduplica por `uuid`, reenviar un lote no duplica.
- **Escaneo** (dos vías, sin dependencia nueva pesada de inicio):
  1. **Lector hardware (keyboard-wedge / intent)**: los terminales de almacén
     (Zebra/Honeywell) emiten el código como texto a un campo con foco. Cero
     librerías. **Vía recomendada para arrancar.**
  2. **Cámara**: requiere un componente de decodificación de barras (ZXing
     port o comercial). Ampliación futura (regla "no deps nuevas sin justificar").
- **Flujo**:
  - **Libre (1/2)**: elegir almacén → `POST inv_recuentos.php` (crea sesión) →
    escanear → cola → sincronizar → **finalizar** (`POST inv_finalizar.php`).
  - **Dirigido (3)**: recoger plantilla → escanear contra el catálogo → cola →
    sincronizar → **finalizar**.
  - **Lote/caducidad** solo si el artículo es trazable (`ESTRAZABLE_ART='S'`).
- **Multi-operario**: varios terminales contra el mismo recuento. El servidor
  acumula todos los eventos; el SKU se agrega sumando.

## 8. Integración en Factuzam (VCL)

- **Nueva unit `inLibInventarioNube.pas`** (en `src/Lib/`), gemela de
  `inLibFotosNube`: `EnviarInventario`, `SincronizarAlmacenes`, `ListarPendientes`,
  `RecogerRecuento`. THTTPClient + JSON. Config en `oAppParams` (categoría nueva
  "Recuentos": `appRecuentoUrl`, `appRecuentoApiKey`, `appRecuentoCarpetaCliente`).
- **Botones en `inMtoInventarios`** (junto a `btnExportarInv`/`btnCargarExcel`),
  preferentemente `TcxButton`:
  - **"Enviar a recuento"**: arma el catálogo del inventario (SKUs de las líneas
    + códigos de barras de `fza_codigos_barras` + descripción + teórica de
    `fza_articulos_stockactual`) y hace `POST inv_enviar.php`. Marca
    `ESRECUENTO_REMOTO_INV='S'` e `INSTANTE_ENVIO_RECUENTO_INV`.
  - **"Recoger recuento"**: `GET inv_recoger.php`, inserta los eventos en
    `fza_inventarios_recuentos`, recalcula `CANTIDAD_FISICA_INVLIN` = suma por
    SKU (reutilizando `CargarDesdeListaSkus`) y pone `FECHA_RECUENTO_INVLIN` =
    último escaneo. Luego el usuario revisa y **APLICA** con el flujo actual.
  - Para recuentos **libres** (origen APP), Factuzam los descubre con
    `inv_pendientes.php` y los vuelca a un `fza_inventarios` nuevo/elegido de ese
    almacén (igual que importar un Excel a un inventario nuevo).
- **Pumpear versión** en `inLibGlobalVar.pas` al implementar (regla repo §6).

## 9. Ciclo de vida

```
DIRIGIDO (opción 3)                         LIBRE (opciones 1/2)
Factuzam: inventario ABIERTO                App: elige almacén
   │  "Enviar a recuento"                      │  crea recuento (origen APP)
   ▼                                           ▼
Servidor: PENDIENTE ─app recoge─▶ EN_RECUENTO ◀── escaneos ──┐
                                      │  "Finalizar"          │
                                      ▼                       │
                                  RECONTADO                   │
   Factuzam "Recoger" ◀── inv_pendientes / inv_recoger ───────┘
   │  rellena físicas + INVREC            Servidor: RECOGIDO
   ▼  (en libre: crea/elige el fza_inventarios del almacén)
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

- **Eventos**: `uuid_evento` único en servidor (`ON DUPLICATE KEY`) → reenvíos
  no duplican. La app marca el evento como "subido" sólo tras 200 OK.
- **Recogida en Factuzam**: la PK de INVREC incluye `UUID_INVREC` → recoger dos
  veces no duplica filas (`INSERT ... ON DUPLICATE KEY`).
- **Cursor incremental**: `inv_recoger.php?desde=<cursor>` y
  `inv_catalogo.php?desde=<id>` traen sólo lo nuevo.

## 12. Fases de entrega

1. **Esquema** ✅ borrador: `recuento_inventarios_factuzam.sql` (INVREC +
   marcadores) y `recuento_inventarios_servidor.sql`. Falta registrar `INVREC`
   en el normalizador y el libro de estilo.
2. **Servidor PHP** ✅ diseño: `recuento_inventarios_php.md` (endpoints +
   esqueletos). Falta subirlo a DreamHost con `config.php` real.
3. **Factuzam VCL**: `inLibInventarioNube` + botones en `inMtoInventarios`.
4. **App Android FMX**: menú (3 opciones), selector de almacén, recoger
   plantilla, escaneo (keyboard-wedge), cola SQLite, sync, finalizar.
5. **Ampliaciones**: escaneo por cámara, zonas/ubicaciones, panel de progreso
   en vivo en Factuzam.

## 13. Decisiones abiertas (para verlo juntos)

1. ✅ **Opción B**: cada escaneo en `fza_inventarios_recuentos` (INVREC).
2. ✅ **Menú de la app**: (1) escanear =+1, (2) escanear + cantidad, (3) recoger
   plantilla.
3. **BBDD del servidor**: asumo **una BBDD MySQL nueva dedicada** en DreamHost
   (`factuzam_recuentos`). ¿Ok?
4. ✅ **Cantidad**: la fija el modo de menú (1 = +1; 2 = cantidad tecleada).
5. ✅ **Lote/caducidad**: solo en artículos trazables (`ESTRAZABLE_ART='S'`).
6. **Cierre de tarea**: ¿finaliza cualquier operario, o sólo un supervisor?
7. ✅ **Plantilla vs libre**: opción 3 exige plantilla; opciones 1/2 son
   recuento libre y preguntan el almacén.
8. ✅ **PK de INVREC**: clave del inventario + `UUID_INVREC` (sin contador
   autoincremental), igual patrón que `fza_inventarios_lineas`.

## 14. Reglas del repo respetadas

- `factuzam_original.sql` intacto; cambios de esquema idempotentes en
  `DESARROLLOS EN CURSO/`.
- Sufijo nuevo `INVREC` siguiendo el libro de estilo BBDD (a registrar).
- Español en código/comentarios; UniDAC; THTTPClient+JSON como el resto.
- Sin dependencias nuevas en el arranque (escaneo por keyboard-wedge).
- Nada aplicado a producción; versión a pumpear al implementar.
