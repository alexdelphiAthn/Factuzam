<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/ventas_lectura.php';

/**
 * Foto de artículo, en PNG, de las que viajan dentro del evento de venta.
 *
 * A diferencia de fotos/imagen.php, que sirve del subsistema fotos_nube y
 * pide el ámbito fotos:leer, esta lee de api_articulos_fotos y le basta con
 * ventas:leer: la misma credencial que ya usa el listado.
 *
 * La resolución replica la de Factuzam (inLibFotos): primero la foto del SKU
 * exacto, luego la del prefijo más largo (normalmente ARTICULO/COLOR) y por
 * último la del artículo. Así una talla sin foto propia enseña la de su
 * color, y un color sin foto la genérica del artículo.
 */

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
    header('Allow: GET');
    responder_error('METODO_NO_PERMITIDO', 'Método no permitido.', 405);
}
$credencial = exigir_token_api('ventas:leer');
$referencia = (string)$credencial['referencia'];
$articulo = texto_consulta($_GET, 'articulo', 20, true);
$sku = texto_consulta($_GET, 'sku', 50);
$pdo = db_api();
try {
    $consulta = $pdo->prepare(
        'SELECT nombre_archivo, tipo_mime, tamano_bytes, huella_sha256, ' .
        'contenido, clave_unidad FROM api_articulos_fotos ' .
        'WHERE referencia = ? AND codigo_articulo = ? ' .
        '  AND (clave_unidad = ? ' .
        "       OR (? <> '' AND ? LIKE CONCAT(clave_unidad, '/%')) " .
        "       OR clave_unidad = '') " .
        'ORDER BY LENGTH(clave_unidad) DESC LIMIT 1'
    );
    $consulta->execute([$referencia, $articulo, $sku, $sku, $sku]);
    $foto = $consulta->fetch();
} catch (Throwable $error) {
    registrar_error_servidor($error);
    responder_error(
        'ERROR_CONSULTANDO_FOTO',
        'No se pudo recuperar la foto.',
        500
    );
}
if (!$foto) {
    responder_error(
        'FOTO_NO_ENCONTRADA',
        'Ese artículo todavía no ha enviado foto con ninguna venta.',
        404
    );
}
$contenido = (string)$foto['contenido'];
$etag = '"' . strtolower((string)$foto['huella_sha256']) . '"';
$nombre = (string)$foto['nombre_archivo'];
$nombreSimple = preg_replace('/[^A-Za-z0-9._-]/', '_', $nombre);
if (!is_string($nombreSimple) || $nombreSimple === '') {
    $nombreSimple = $articulo . '.png';
}
header('Content-Type: ' . (string)$foto['tipo_mime']);
header('ETag: ' . $etag);
header('Cache-Control: private, max-age=86400');
header('X-Foto-Clave: ' . (string)$foto['clave_unidad']);
header('Content-Disposition: inline; filename="' . $nombreSimple . '"');
if (cabecera_http('If-None-Match') === $etag) {
    http_response_code(304);
    exit;
}
header('Content-Length: ' . strlen($contenido));
echo $contenido;
exit;
