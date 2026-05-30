<?php
// App: marca el recuento como RECONTADO (listo para que Factuzam lo recoja).
require __DIR__ . '/comun.php';
$d = exigir_dispositivo();
$in = cuerpo_json();
$idRec = (int)($in['id_recuento'] ?? 0);
$st = db()->prepare(
  'UPDATE inv_recuentos SET estado = "RECONTADO"
    WHERE id = ? AND carpeta_cliente = ?
      AND estado IN ("EN_RECUENTO","PENDIENTE")');
$st->execute([$idRec, $d['carpeta_cliente']]);
json_salida(['estado' => 'RECONTADO']);
