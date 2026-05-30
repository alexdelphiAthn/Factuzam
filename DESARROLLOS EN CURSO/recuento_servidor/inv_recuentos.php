<?php
// App:
//   GET  -> plantillas (origen FACTUZAM, tipo RECUENTO) listas para recontar.
//   POST -> crea un recuento LIBRE o un TRASPASO de un almacén. Reutiliza uno
//           abierto del mismo almacén (y destino, si es traspaso).
require __DIR__ . '/comun.php';
$d = exigir_dispositivo();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
  $st = db()->prepare(
    'SELECT id, codigo_emp, codigo_alm, serie, numero, descripcion, estado
       FROM inv_recuentos
      WHERE carpeta_cliente = ? AND origen = "FACTUZAM" AND tipo = "RECUENTO"
        AND estado IN ("PENDIENTE","EN_RECUENTO")
      ORDER BY instante_envio DESC');
  $st->execute([$d['carpeta_cliente']]);
  json_salida($st->fetchAll());
}

$in = cuerpo_json();
$alm = $in['codigo_alm'] ?? '';
if ($alm === '') {
  json_error('codigo_alm es obligatorio');
}
$tipo = (($in['tipo'] ?? 'RECUENTO') === 'TRASPASO') ? 'TRASPASO' : 'RECUENTO';
$destino = $in['codigo_alm_destino'] ?? null;
if ($tipo === 'TRASPASO' && !$destino) {
  json_error('codigo_alm_destino es obligatorio en traspaso');
}
// Reutilizar una sesión abierta equivalente para no duplicar.
if ($tipo === 'TRASPASO') {
  $q = db()->prepare(
    'SELECT id FROM inv_recuentos
      WHERE carpeta_cliente = ? AND origen = "APP" AND tipo = "TRASPASO"
        AND codigo_alm = ? AND codigo_alm_destino = ?
        AND estado IN ("PENDIENTE","EN_RECUENTO") LIMIT 1');
  $q->execute([$d['carpeta_cliente'], $alm, $destino]);
} else {
  $q = db()->prepare(
    'SELECT id FROM inv_recuentos
      WHERE carpeta_cliente = ? AND origen = "APP" AND tipo = "RECUENTO"
        AND codigo_alm = ? AND estado IN ("PENDIENTE","EN_RECUENTO") LIMIT 1');
  $q->execute([$d['carpeta_cliente'], $alm]);
}
$row = $q->fetch();
if ($row) {
  json_salida(['id_recuento' => (int)$row['id']]);
}
$st = db()->prepare(
  'INSERT INTO inv_recuentos
     (carpeta_cliente, origen, modo, tipo, codigo_emp, codigo_alm,
      codigo_alm_destino, descripcion, estado, dispositivo_origen)
   VALUES (?, "APP", "LIBRE", ?, ?, ?, ?, ?, "EN_RECUENTO", ?)');
$st->execute([$d['carpeta_cliente'], $tipo, $in['codigo_emp'] ?? null, $alm,
              $destino, $in['descripcion'] ?? null, $d['nombre']]);
json_salida(['id_recuento' => (int)db()->lastInsertId()]);
