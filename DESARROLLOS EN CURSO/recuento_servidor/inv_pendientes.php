<?php
// Factuzam: recuentos/traspasos RECONTADO listos para recoger.
require __DIR__ . '/comun.php';
exigir_api_key();
$car = $_GET['carpeta_cliente'] ?? '';
if ($car === '') {
  json_error('Falta carpeta_cliente');
}
$st = db()->prepare(
  'SELECT id, origen, tipo, codigo_emp, codigo_alm, codigo_alm_destino,
          serie, numero, descripcion
     FROM inv_recuentos
    WHERE carpeta_cliente = ? AND estado = "RECONTADO"
    ORDER BY instante_modif');
$st->execute([$car]);
json_salida($st->fetchAll());
