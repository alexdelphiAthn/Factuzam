<?php
// App: reabre un recuento RECONTADO para seguir contando (vuelve a EN_RECUENTO).
require __DIR__ . '/comun.php';
$d = exigir_dispositivo();
$in = cuerpo_json();
$idRec = (int)($in['id_recuento'] ?? 0);
$st = db()->prepare(
  'UPDATE inv_recuentos SET estado = "EN_RECUENTO"
    WHERE id = ? AND carpeta_cliente = ? AND estado = "RECONTADO"');
$st->execute([$idRec, $d['carpeta_cliente']]);
json_salida(['estado' => 'EN_RECUENTO']);
