<?php
// App: sube un lote de escaneos. Idempotente por uuid_evento.
require __DIR__ . '/comun.php';
$disp = exigir_dispositivo();
$in = cuerpo_json();
$idRec = (int)($in['id_recuento'] ?? 0);
$eventos = $in['eventos'] ?? [];
if ($idRec <= 0 || !is_array($eventos)) {
  json_error('id_recuento y eventos son obligatorios');
}
$st = db()->prepare(
  'SELECT id FROM inv_recuentos WHERE id = ? AND carpeta_cliente = ?');
$st->execute([$idRec, $disp['carpeta_cliente']]);
if (!$st->fetch()) {
  json_error('Recuento no encontrado', 404);
}
$ins = db()->prepare(
  'INSERT INTO inv_eventos
     (id_recuento, uuid_evento, codigo_barras, codigo_articulo, codigo_unidad,
      cantidad, lote, fecha_caducidad, instante_recuento, operario,
      dispositivo, zona)
   VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
   ON DUPLICATE KEY UPDATE id = id');
$aceptados = 0; $duplicados = 0;
db()->beginTransaction();
foreach ($eventos as $e) {
  $uuid = $e['uuid'] ?? '';
  if ($uuid === '') {
    continue;
  }
  $cad = ($e['fecha_caducidad'] ?? '') !== '' ? $e['fecha_caducidad'] : null;
  $ins->execute([
    $idRec, $uuid, $e['codigo_barras'] ?? null, $e['codigo_articulo'] ?? null,
    $e['codigo_unidad'] ?? null, $e['cantidad'] ?? 1, $e['lote'] ?? null,
    $cad, $e['instante_recuento'] ?? date('Y-m-d H:i:s'),
    $in['operario'] ?? ($disp['operario'] ?? null),
    $in['dispositivo'] ?? $disp['nombre'], $e['zona'] ?? null]);
  if ($ins->rowCount() > 0) {
    $aceptados++;
  } else {
    $duplicados++;
  }
}
db()->prepare(
  'UPDATE inv_recuentos SET estado = "EN_RECUENTO"
    WHERE id = ? AND estado = "PENDIENTE"')->execute([$idRec]);
db()->commit();
json_salida(['aceptados' => $aceptados, 'duplicados' => $duplicados]);
