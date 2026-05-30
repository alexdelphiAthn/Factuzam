<?php
// App: alta de un dispositivo. Devuelve el token que usará en X-API-Key.
require __DIR__ . '/comun.php';

$car = $_SERVER['HTTP_X_CARPETA'] ?? '';
if ($car === '') {
  json_error('Falta X-Carpeta', 401);
}
$in = cuerpo_json();
if (($in['clave_alta'] ?? '') !== CFG_CLAVE_ALTA) {
  json_error('Clave de alta incorrecta', 401);
}
$token = bin2hex(random_bytes(32));   // 64 chars hex
$st = db()->prepare(
  'INSERT INTO inv_dispositivos (carpeta_cliente, nombre, operario, token,
     esactivo) VALUES (?, ?, ?, ?, "S")');
$st->execute([$car, $in['nombre'] ?? 'PDA', $in['operario'] ?? null, $token]);
json_salida(['token' => $token]);
