<?php
// Factuzam: recoge el recuento. Devuelve los eventos (crudo) a partir de un
// cursor y el agregado por SKU (= lo que Factuzam mete con CargarDesdeListaSkus).
// Con marcar=1 pasa el recuento a RECOGIDO.
require __DIR__ . '/comun.php';
exigir_api_key();
$idRec  = (int)($_GET['id_recuento'] ?? 0);
$desde  = (int)($_GET['desde'] ?? 0);
$marcar = ($_GET['marcar'] ?? '') === '1';
if ($idRec <= 0) {
  json_error('id_recuento es obligatorio');
}
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
foreach ($eventos as $e) {
  $cursor = max($cursor, (int)$e['id']);
}
$ag = db()->prepare(
  'SELECT codigo_unidad, SUM(cantidad) AS cantidad
     FROM inv_eventos
    WHERE id_recuento = ? AND anulado = "N" AND codigo_unidad IS NOT NULL
    GROUP BY codigo_unidad');
$ag->execute([$idRec]);
$agregado = $ag->fetchAll();
if ($marcar) {
  db()->prepare(
    'UPDATE inv_recuentos SET estado = "RECOGIDO", instante_recogida = NOW()
      WHERE id = ?')->execute([$idRec]);
}
json_salida(['eventos' => $eventos, 'agregado' => $agregado,
             'cursor' => $cursor]);
