<?php
// App: catálogo (líneas de la plantilla) de un recuento dirigido. Paginado por
// cursor ?desde=<id>.
require __DIR__ . '/comun.php';
$d = exigir_dispositivo();
$id = (int)($_GET['id_recuento'] ?? 0);
$desde = (int)($_GET['desde'] ?? 0);
$chk = db()->prepare(
  'SELECT id FROM inv_recuentos WHERE id = ? AND carpeta_cliente = ?');
$chk->execute([$id, $d['carpeta_cliente']]);
if (!$chk->fetch()) {
  json_error('Recuento no encontrado', 404);
}
$st = db()->prepare(
  'SELECT id, codigo_articulo, codigo_unidad, descripcion, codigo_barras,
          cantidad_teorica, estrazable
     FROM inv_catalogo
    WHERE id_recuento = ? AND id > ? ORDER BY id');
$st->execute([$id, $desde]);
json_salida($st->fetchAll());
