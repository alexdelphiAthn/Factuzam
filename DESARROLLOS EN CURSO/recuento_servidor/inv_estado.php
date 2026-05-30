<?php
// Factuzam: estado + progreso de un recuento.
require __DIR__ . '/comun.php';
exigir_api_key();
$id = (int)($_GET['id_recuento'] ?? 0);
$st = db()->prepare(
  'SELECT r.estado, r.tipo,
          (SELECT COUNT(*) FROM inv_eventos e
            WHERE e.id_recuento = r.id AND e.anulado = "N") AS n_eventos,
          (SELECT COUNT(DISTINCT codigo_unidad) FROM inv_eventos e
            WHERE e.id_recuento = r.id AND e.anulado = "N") AS n_skus,
          (SELECT MAX(instante_recuento) FROM inv_eventos e
            WHERE e.id_recuento = r.id) AS ultimo_escaneo
     FROM inv_recuentos r WHERE r.id = ?');
$st->execute([$id]);
$row = $st->fetch();
if (!$row) {
  json_error('Recuento no encontrado', 404);
}
json_salida($row);
