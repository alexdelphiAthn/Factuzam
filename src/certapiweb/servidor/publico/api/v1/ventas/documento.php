<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/ventas_lectura.php';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
    header('Allow: GET');
    responder_error('METODO_NO_PERMITIDO', 'Método no permitido.', 405);
}
$credencial = exigir_token_api('ventas:leer');
$referencia = (string)$credencial['referencia'];
$empresa = texto_consulta($_GET, 'empresa', 20, true);
$serie = texto_consulta($_GET, 'serie', 20, true);
$numero = texto_consulta($_GET, 'numero', 20, true);
$tipo = tipo_documento_consulta($_GET, 'tipo');
$pdo = db_api();
try {
    $venta = buscar_venta($pdo, $referencia, $empresa, $serie, $numero);
    $consulta = $pdo->prepare(
        'SELECT nombre_archivo, tipo_mime, tamano_bytes, ' .
        'huella_sha256, contenido FROM api_ventas_documentos ' .
        'WHERE id_venta = ? AND tipo_documento = ? LIMIT 1'
    );
    $consulta->execute([(int)$venta['id'], $tipo]);
    $documento = $consulta->fetch();
} catch (Throwable $error) {
    registrar_error_servidor($error);
    responder_error(
        'ERROR_CONSULTANDO_DOCUMENTO',
        'No se pudo recuperar el documento.',
        500
    );
}
if (!$documento) {
    responder_error(
        'DOCUMENTO_NO_ENCONTRADO',
        'La venta no tiene almacenado ese documento.',
        404
    );
}
$contenido = (string)$documento['contenido'];
$nombre = (string)$documento['nombre_archivo'];
if (basename($nombre) !== $nombre || $nombre === '') {
    $nombre = $tipo . '.pdf';
}
// El nombre puede traer comillas o acentos: se manda una versión ASCII
// entrecomillada y el nombre real codificado en filename*.
$nombreSimple = preg_replace('/[^A-Za-z0-9._-]/', '_', $nombre);
if (!is_string($nombreSimple) || $nombreSimple === '') {
    $nombreSimple = $tipo . '.pdf';
}
header('Content-Type: ' . (string)$documento['tipo_mime']);
header('Content-Length: ' . strlen($contenido));
header(
    'Content-Disposition: attachment; filename="' . $nombreSimple .
    '"; filename*=UTF-8\'\'' . rawurlencode($nombre)
);
header('X-Venta-Sha256: ' . (string)$documento['huella_sha256']);
header('X-Venta-Tamano: ' . (string)$documento['tamano_bytes']);
header('Cache-Control: private, no-store');
echo $contenido;
exit;
