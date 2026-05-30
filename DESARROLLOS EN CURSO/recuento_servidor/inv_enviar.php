<?php
// Factuzam: crea/reemplaza una plantilla (recuento dirigido) + su catálogo.
// Idempotente por la clave del inventario (carpeta+emp+alm+serie+numero).
require __DIR__ . '/comun.php';
exigir_api_key();
$in = cuerpo_json();
foreach (['carpeta_cliente','codigo_emp','codigo_alm','serie','numero'] as $c) {
  if (empty($in[$c])) {
    json_error("Falta $c");
  }
}
db()->beginTransaction();
$st = db()->prepare(
  'INSERT INTO inv_recuentos
     (carpeta_cliente, origen, modo, tipo, codigo_emp, codigo_alm, serie,
      numero, descripcion, estado, usuario_envio, instante_envio)
   VALUES (?, "FACTUZAM", ?, "RECUENTO", ?, ?, ?, ?, ?, "PENDIENTE", ?, NOW())
   ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion),
     modo = VALUES(modo), estado = "PENDIENTE", instante_envio = NOW(),
     id = LAST_INSERT_ID(id)');
$st->execute([$in['carpeta_cliente'], $in['modo'] ?? 'DIRIGIDO',
  $in['codigo_emp'], $in['codigo_alm'], $in['serie'], $in['numero'],
  $in['descripcion'] ?? null, $in['usuario_envio'] ?? null]);
$idRec = (int)db()->lastInsertId();
db()->prepare('DELETE FROM inv_catalogo WHERE id_recuento = ?')
   ->execute([$idRec]);
$insCat = db()->prepare(
  'INSERT INTO inv_catalogo
     (id_recuento, codigo_articulo, codigo_unidad, descripcion, codigo_barras,
      cantidad_teorica, estrazable)
   VALUES (?,?,?,?,?,?,?)');
foreach (($in['lineas'] ?? []) as $l) {
  $insCat->execute([$idRec, $l['codigo_articulo'] ?? '',
    $l['codigo_unidad'] ?? '', $l['descripcion'] ?? null,
    $l['codigo_barras'] ?? null, $l['cantidad_teorica'] ?? null,
    $l['estrazable'] ?? 'N']);
}
db()->commit();
json_salida(['id_recuento' => $idRec]);
