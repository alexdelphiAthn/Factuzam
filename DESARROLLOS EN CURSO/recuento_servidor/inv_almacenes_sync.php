<?php
// Factuzam: sincroniza la lista de almacenes (para el selector de la app).
require __DIR__ . '/comun.php';
exigir_api_key();
$in = cuerpo_json();
$car = $in['carpeta_cliente'] ?? '';
if ($car === '') {
  json_error('Falta carpeta_cliente');
}
$alms = $in['almacenes'] ?? [];
$up = db()->prepare(
  'INSERT INTO inv_almacenes (carpeta_cliente, codigo_emp, codigo_alm, nombre,
     esactivo) VALUES (?,?,?,?,?)
   ON DUPLICATE KEY UPDATE nombre = VALUES(nombre),
     esactivo = VALUES(esactivo)');
$n = 0;
db()->beginTransaction();
foreach ($alms as $a) {
  $up->execute([$car, $a['codigo_emp'] ?? '', $a['codigo_alm'] ?? '',
                $a['nombre'] ?? null, $a['esactivo'] ?? 'S']);
  $n++;
}
db()->commit();
json_salida(['sincronizados' => $n]);
