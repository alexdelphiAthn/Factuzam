<?php
// ============================================================================
//  Bootstrap común: PDO, helpers JSON y autenticación.
//    - Factuzam  -> cabecera X-API-Key = CFG_API_KEY (servidor a servidor).
//    - App        -> cabecera X-API-Key = token de inv_dispositivos + X-Carpeta.
// ============================================================================
declare(strict_types=1);
require __DIR__ . '/config.php';

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

// Factuzam: la X-API-Key debe coincidir con la clave maestra del config.
function exigir_api_key(): void {
  $k = $_SERVER['HTTP_X_API_KEY'] ?? '';
  if (!hash_equals(CFG_API_KEY, $k)) {
    json_error('No autorizado', 401);
  }
}

// App: el token (X-API-Key) debe existir y estar activo para esa carpeta.
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
