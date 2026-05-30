# Servidor PHP de recuentos (diseño)

API REST en PHP plano (estilo `download_foto.php`) sobre la BBDD MySQL de
`recuento_inventarios_servidor.sql`. Pensado para **DreamHost compartido**:
PHP 8.x, PDO MySQL, HTTPS (Let's Encrypt), sin frameworks ni procesos largos.

> Acompaña a `recuento_inventarios_app.md` (diseño general) y a
> `recuento_inventarios_servidor.sql` (esquema). Esto es el contrato + los
> esqueletos; cuando se apruebe se sube a una carpeta del hosting.

## 1. Estructura de ficheros

```
/recuentos/
  config.php        Credenciales (fuera del control de versiones). DB + API key.
  comun.php         Bootstrap: PDO, helpers JSON, auth (X-API-Key / token).
  # --- App (auth: token de dispositivo) ---
  disp_registrar.php   Alta de dispositivo -> devuelve token.
  inv_almacenes.php     GET lista de almacenes (selector de recuento libre).
  inv_recuentos.php     GET plantillas pendientes / POST crear recuento libre.
  inv_catalogo.php      GET catálogo de una plantilla (paginado).
  inv_eventos.php       POST lote de escaneos (idempotente por uuid).
  inv_finalizar.php     POST marca el recuento como RECONTADO.
  # --- Factuzam (auth: X-API-Key) ---
  inv_enviar.php        POST crea/reemplaza plantilla + catálogo (DIRIGIDO).
  inv_almacenes_sync.php POST sincroniza la lista de almacenes.
  inv_pendientes.php    GET recuentos RECONTADO listos para recoger.
  inv_recoger.php       GET eventos + agregado por SKU; marca RECOGIDO.
  inv_estado.php        GET estado + progreso de un recuento.
```

## 2. Autenticación

| Canal | Cabecera | Comprobación |
|---|---|---|
| Factuzam ↔ servidor | `X-API-Key: <clave>` | igual a `config.php` (server-to-server) |
| App ↔ servidor | `X-API-Key: <token>` + `X-Carpeta: <carpeta_cliente>` | el token existe en `inv_dispositivos` (esactivo='S') y pertenece a esa carpeta |

`carpeta_cliente` aísla cada cliente (igual que el servidor de fotos). Todo
sobre HTTPS. Errores siempre `{ "message": "..." }` + status HTTP.

## 3. Endpoints (contrato)

### App (token de dispositivo)

| Método · script | Entrada | Salida |
|---|---|---|
| `POST disp_registrar.php` | `{nombre, operario, clave_alta}` | `{token}` |
| `GET inv_almacenes.php` | — | `[{codigo_emp, codigo_alm, nombre}]` |
| `GET inv_recuentos.php` | — | plantillas `PENDIENTE/EN_RECUENTO` `[{id, codigo_alm, descripcion, ...}]` |
| `POST inv_recuentos.php` | `{codigo_emp, codigo_alm, descripcion}` (recuento LIBRE) | `{id_recuento}` |
| `GET inv_catalogo.php?id_recuento=..&desde=..` | — | `[{codigo_articulo, codigo_unidad, descripcion, codigo_barras, cantidad_teorica, estrazable}]` |
| `POST inv_eventos.php` | `{id_recuento, dispositivo, operario, eventos:[...]}` | `{aceptados, duplicados}` |
| `POST inv_finalizar.php` | `{id_recuento}` | `{estado:"RECONTADO"}` |

### Factuzam (X-API-Key)

| Método · script | Entrada | Salida |
|---|---|---|
| `POST inv_enviar.php` | `{carpeta_cliente, codigo_emp, codigo_alm, serie, numero, descripcion, modo, lineas:[...]}` | `{id_recuento}` |
| `POST inv_almacenes_sync.php` | `{carpeta_cliente, almacenes:[{codigo_emp, codigo_alm, nombre, esactivo}]}` | `{sincronizados}` |
| `GET inv_pendientes.php?carpeta_cliente=..` | — | recuentos `RECONTADO` `[{id, origen, codigo_alm, serie, numero}]` |
| `GET inv_recoger.php?id_recuento=..&desde=..&marcar=1` | — | `{eventos:[...], agregado:[{codigo_unidad, cantidad}], cursor}` |
| `GET inv_estado.php?id_recuento=..` | — | `{estado, n_eventos, n_skus, ultimo_escaneo}` |

Ejemplo `POST inv_eventos.php`:

```json
{ "id_recuento": 42, "dispositivo": "PDA-03", "operario": "MARTA",
  "eventos": [
    { "uuid": "f1c2e6b0-...", "codigo_barras": "8412345000123",
      "codigo_unidad": "CAMISA/AZUL/M", "cantidad": 1,
      "lote": "", "instante_recuento": "2026-05-30T11:42:07" }
  ] }
```

## 4. Esqueletos

### comun.php

```php
<?php
declare(strict_types=1);
require __DIR__ . '/config.php';   // define CFG_DB_*, CFG_API_KEY

header('Content-Type: application/json; charset=utf-8');

function db(): PDO {
  static $pdo = null;
  if ($pdo === null) {
    $pdo = new PDO(
      'mysql:host=' . CFG_DB_HOST . ';dbname=' . CFG_DB_NAME . ';charset=utf8mb4',
      CFG_DB_USER, CFG_DB_PASS,
      [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
       PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
  }
  return $pdo;
}

function json_salida($data, int $status = 200): void {
  http_response_code($status);
  echo json_encode($data, JSON_UNESCAPED_UNICODE);
  exit;
}

function json_error(string $msg, int $status = 400): void {
  json_salida(['message' => $msg], $status);
}

function cuerpo_json(): array {
  $raw = file_get_contents('php://input');
  $j = json_decode($raw, true);
  if (!is_array($j)) {
    json_error('JSON inválido', 400);
  }
  return $j;
}

// Factuzam: la X-API-Key debe coincidir con la del config.
function exigir_api_key(): void {
  $k = $_SERVER['HTTP_X_API_KEY'] ?? '';
  if (!hash_equals(CFG_API_KEY, $k)) {
    json_error('No autorizado', 401);
  }
}

// App: el token debe existir y estar activo; devuelve la fila del dispositivo.
function exigir_dispositivo(): array {
  $tok = $_SERVER['HTTP_X_API_KEY'] ?? '';
  $car = $_SERVER['HTTP_X_CARPETA'] ?? '';
  if ($tok === '' || $car === '') {
    json_error('Faltan credenciales', 401);
  }
  $st = db()->prepare(
    'SELECT * FROM inv_dispositivos
      WHERE token = ? AND carpeta_cliente = ? AND esactivo = "S"');
  $st->execute([$tok, $car]);
  $d = $st->fetch();
  if (!$d) {
    json_error('Dispositivo no autorizado', 401);
  }
  return $d;
}
```

### inv_eventos.php (subida de escaneos, idempotente)

```php
<?php
require __DIR__ . '/comun.php';
$disp = exigir_dispositivo();
$in = cuerpo_json();
$idRec = (int)($in['id_recuento'] ?? 0);
$eventos = $in['eventos'] ?? [];
if ($idRec <= 0 || !is_array($eventos)) {
  json_error('id_recuento y eventos son obligatorios');
}
// El recuento debe ser de la misma carpeta del dispositivo.
$st = db()->prepare(
  'SELECT id FROM inv_recuentos WHERE id = ? AND carpeta_cliente = ?');
$st->execute([$idRec, $disp['carpeta_cliente']]);
if (!$st->fetch()) {
  json_error('Recuento no encontrado', 404);
}
$sql = 'INSERT INTO inv_eventos
          (id_recuento, uuid_evento, codigo_barras, codigo_articulo,
           codigo_unidad, cantidad, lote, fecha_caducidad, instante_recuento,
           operario, dispositivo, zona)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
        ON DUPLICATE KEY UPDATE id = id';   // dedupe por uq_evento_uuid
$ins = db()->prepare($sql);
$aceptados = 0; $duplicados = 0;
db()->beginTransaction();
foreach ($eventos as $e) {
  $uuid = $e['uuid'] ?? '';
  if ($uuid === '') { continue; }
  $ins->execute([
    $idRec, $uuid, $e['codigo_barras'] ?? null, $e['codigo_articulo'] ?? null,
    $e['codigo_unidad'] ?? null, $e['cantidad'] ?? 1, $e['lote'] ?? null,
    $e['fecha_caducidad'] ?? null, $e['instante_recuento'] ?? date('Y-m-d H:i:s'),
    $in['operario'] ?? ($disp['operario'] ?? null), $in['dispositivo'] ?? $disp['nombre'],
    $e['zona'] ?? null]);
  if ($ins->rowCount() > 0) { $aceptados++; } else { $duplicados++; }
}
// El primer lote pasa el recuento a EN_RECUENTO.
db()->prepare(
  'UPDATE inv_recuentos SET estado = "EN_RECUENTO"
    WHERE id = ? AND estado = "PENDIENTE"')->execute([$idRec]);
db()->commit();
json_salida(['aceptados' => $aceptados, 'duplicados' => $duplicados]);
```

### inv_finalizar.php

```php
<?php
require __DIR__ . '/comun.php';
$disp = exigir_dispositivo();
$in = cuerpo_json();
$idRec = (int)($in['id_recuento'] ?? 0);
$st = db()->prepare(
  'UPDATE inv_recuentos SET estado = "RECONTADO"
    WHERE id = ? AND carpeta_cliente = ? AND estado IN ("EN_RECUENTO","PENDIENTE")');
$st->execute([$idRec, $disp['carpeta_cliente']]);
json_salida(['estado' => 'RECONTADO']);
```

### inv_recuentos.php (GET plantillas / POST crear libre)

```php
<?php
require __DIR__ . '/comun.php';
$disp = exigir_dispositivo();
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
  // Plantillas (origen FACTUZAM) listas para recontar (opción 3 del menú).
  $st = db()->prepare(
    'SELECT id, codigo_emp, codigo_alm, serie, numero, descripcion, estado
       FROM inv_recuentos
      WHERE carpeta_cliente = ? AND origen = "FACTUZAM"
        AND estado IN ("PENDIENTE","EN_RECUENTO")
      ORDER BY instante_envio DESC');
  $st->execute([$disp['carpeta_cliente']]);
  json_salida($st->fetchAll());
}
// POST: recuento LIBRE de un almacén (opciones 1/2). Reutiliza si ya hay uno
// abierto de ese almacén para no duplicar.
$in = cuerpo_json();
$alm = $in['codigo_alm'] ?? '';
if ($alm === '') { json_error('codigo_alm es obligatorio'); }
$st = db()->prepare(
  'SELECT id FROM inv_recuentos
    WHERE carpeta_cliente = ? AND origen = "APP" AND codigo_alm = ?
      AND estado IN ("PENDIENTE","EN_RECUENTO") LIMIT 1');
$st->execute([$disp['carpeta_cliente'], $alm]);
$row = $st->fetch();
if ($row) { json_salida(['id_recuento' => (int)$row['id']]); }
$st = db()->prepare(
  'INSERT INTO inv_recuentos
     (carpeta_cliente, origen, modo, codigo_emp, codigo_alm, descripcion,
      estado, dispositivo_origen)
   VALUES (?, "APP", "LIBRE", ?, ?, ?, "EN_RECUENTO", ?)');
$st->execute([$disp['carpeta_cliente'], $in['codigo_emp'] ?? null, $alm,
              $in['descripcion'] ?? null, $disp['nombre']]);
json_salida(['id_recuento' => (int)db()->lastInsertId()]);
```

### inv_enviar.php (Factuzam crea/reemplaza una plantilla)

```php
<?php
require __DIR__ . '/comun.php';
exigir_api_key();
$in = cuerpo_json();
foreach (['carpeta_cliente','codigo_emp','codigo_alm','serie','numero'] as $c) {
  if (empty($in[$c])) { json_error("Falta $c"); }
}
db()->beginTransaction();
// Upsert de la cabecera por la clave del inventario.
$st = db()->prepare(
  'INSERT INTO inv_recuentos
     (carpeta_cliente, origen, modo, codigo_emp, codigo_alm, serie, numero,
      descripcion, estado, usuario_envio, instante_envio)
   VALUES (?, "FACTUZAM", ?, ?, ?, ?, ?, ?, "PENDIENTE", ?, NOW())
   ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion),
     modo = VALUES(modo), estado = "PENDIENTE", instante_envio = NOW(),
     id = LAST_INSERT_ID(id)');
$st->execute([$in['carpeta_cliente'], $in['modo'] ?? 'DIRIGIDO',
  $in['codigo_emp'], $in['codigo_alm'], $in['serie'], $in['numero'],
  $in['descripcion'] ?? null, $in['usuario_envio'] ?? null]);
$idRec = (int)db()->lastInsertId();
// Catálogo: se reemplaza entero.
db()->prepare('DELETE FROM inv_catalogo WHERE id_recuento = ?')->execute([$idRec]);
$insCat = db()->prepare(
  'INSERT INTO inv_catalogo
     (id_recuento, codigo_articulo, codigo_unidad, descripcion, codigo_barras,
      cantidad_teorica, estrazable)
   VALUES (?,?,?,?,?,?,?)');
foreach (($in['lineas'] ?? []) as $l) {
  $insCat->execute([$idRec, $l['codigo_articulo'] ?? '', $l['codigo_unidad'] ?? '',
    $l['descripcion'] ?? null, $l['codigo_barras'] ?? null,
    $l['cantidad_teorica'] ?? null, $l['estrazable'] ?? 'N']);
}
db()->commit();
json_salida(['id_recuento' => $idRec]);
```

### inv_recoger.php (Factuzam recoge el recuento)

```php
<?php
require __DIR__ . '/comun.php';
exigir_api_key();
$idRec  = (int)($_GET['id_recuento'] ?? 0);
$desde  = (int)($_GET['desde'] ?? 0);          // cursor incremental
$marcar = ($_GET['marcar'] ?? '') === '1';
if ($idRec <= 0) { json_error('id_recuento es obligatorio'); }
// Eventos nuevos (no anulados) a partir del cursor.
$st = db()->prepare(
  'SELECT id, uuid_evento, codigo_barras, codigo_articulo, codigo_unidad,
          cantidad, lote, fecha_caducidad, instante_recuento, operario,
          dispositivo, zona
     FROM inv_eventos
    WHERE id_recuento = ? AND id > ? AND anulado = "N"
    ORDER BY id');
$st->execute([$idRec, $desde]);
$eventos = $st->fetchAll();
$cursor = $desde;
foreach ($eventos as $e) { $cursor = max($cursor, (int)$e['id']); }
// Agregado por SKU (= lo que Factuzam mete con CargarDesdeListaSkus).
$ag = db()->prepare(
  'SELECT codigo_unidad, SUM(cantidad) AS cantidad
     FROM inv_eventos
    WHERE id_recuento = ? AND anulado = "N" AND codigo_unidad IS NOT NULL
    GROUP BY codigo_unidad');
$ag->execute([$idRec]);
if ($marcar) {
  db()->prepare(
    'UPDATE inv_recuentos SET estado = "RECOGIDO", instante_recogida = NOW()
      WHERE id = ?')->execute([$idRec]);
}
json_salida([
  'eventos'  => $eventos,
  'agregado' => $ag->fetchAll(),
  'cursor'   => $cursor]);
```

Los demás (`disp_registrar.php`, `inv_almacenes.php`, `inv_catalogo.php`,
`inv_almacenes_sync.php`, `inv_pendientes.php`, `inv_estado.php`) siguen el
mismo molde: `require comun.php` → auth → consulta PDO → `json_salida(...)`.

## 5. Notas

- **Idempotencia**: `uq_evento_uuid` + `ON DUPLICATE KEY` ⇒ reenviar un lote no
  duplica. La app marca el evento como "subido" sólo tras 200 OK.
- **Cursor**: `inv_recoger.php?desde=<cursor>` permite recoger incrementalmente
  (Factuzam guarda el último `cursor` por recuento).
- **DreamHost**: límite de tamaño de POST y de tiempo de ejecución → subir los
  eventos por lotes (p.ej. 200-500 por petición). PDO con sentencias preparadas
  (sin SQL dinámico con concatenación).
- **Recuento libre** (opciones 1/2): no tiene `serie/numero`; al recoger,
  Factuzam crea/elige un `fza_inventarios` para ese almacén y vuelca el agregado
  (igual que importar un Excel a un inventario nuevo).
