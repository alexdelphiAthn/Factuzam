<?php
// App: lista de almacenes para el selector (recuento libre / traspaso).
require __DIR__ . '/comun.php';
$d = exigir_dispositivo();
$st = db()->prepare(
  'SELECT codigo_emp, codigo_alm, nombre FROM inv_almacenes
    WHERE carpeta_cliente = ? AND esactivo = "S" ORDER BY codigo_alm');
$st->execute([$d['carpeta_cliente']]);
json_salida($st->fetchAll());
