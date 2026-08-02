<?php
declare(strict_types=1);

require_once __DIR__ . '/lib.php';

exigir_admin();
$id = (int)($_GET['id'] ?? 0);
$consulta = bbdd()->prepare(
    'SELECT * FROM soporte_error_adjuntos WHERE ID_ADJUNTO = :id'
);
$consulta->execute([':id' => $id]);
$adjunto = $consulta->fetch();
if (!is_array($adjunto)) {
    http_response_code(404);
    exit('Adjunto no encontrado.');
}
$raiz = realpath(ruta_almacen_privado());
$ruta = realpath((string)$adjunto['RUTA_PRIVADA']);
if ($raiz === false || $ruta === false ||
    strpos($ruta, $raiz . DIRECTORY_SEPARATOR) !== 0 ||
    !is_file($ruta)) {
    http_response_code(404);
    exit('Adjunto no disponible.');
}
$inline = isset($_GET['inline']) &&
    (string)$adjunto['TIPO_ADJUNTO'] === 'PANTALLAZO';
$disposicion = $inline ? 'inline' : 'attachment';
$nombre = (string)$adjunto['TIPO_ADJUNTO'] === 'PANTALLAZO'
    ? 'pantallazo.png'
    : 'factuzam.log';
header('Content-Type: ' . (string)$adjunto['TIPO_MIME']);
header('Content-Length: ' . (string)filesize($ruta));
header('Content-Disposition: ' . $disposicion . '; filename="' . $nombre . '"');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: private, no-store');
readfile($ruta);
