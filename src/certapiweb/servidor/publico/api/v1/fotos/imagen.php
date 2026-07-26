<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/fotos.php';

/**
 * Devuelve UNA foto en PNG, no un ZIP.
 *
 * descargar.php empaqueta todas las fotos que casan y sirve un ZIP, que va
 * bien para el escritorio pero no para pintar miniaturas en una lista del
 * móvil. Aquí se elige la primera coincidencia y se sirve la imagen tal cual,
 * con ETag para que el móvil no se la vuelva a bajar en cada scroll.
 */

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
    header('Allow: GET');
    responder_error('METODO_NO_PERMITIDO', 'Método no permitido.', 405);
}
$credencial = exigir_token_api('fotos:leer');
$referencia = exigir_referencia_fotos(
    $credencial,
    referencia_entrada($_GET)
);
$articulo = parametro_foto($_GET, 'articulo');
$color = parametro_foto($_GET, 'color', false);
$indice = parametro_foto($_GET, 'indice', false);
$resolucionEntrada = $_GET['resolucion'] ?? '300';
$resolucion = is_string($resolucionEntrada)
    ? strtolower(trim($resolucionEntrada))
    : '';
if (!in_array($resolucion, ['150', '300', 'real'], true)) {
    responder_error(
        'RESOLUCION_INVALIDA',
        'Las resoluciones permitidas son 150, 300 y real.',
        422
    );
}
$directorio = directorio_fotos_referencia($referencia, false);
if (!is_dir($directorio)) {
    responder_error(
        'FOTO_NO_ENCONTRADA',
        'La instalación todavía no tiene fotos en el servidor.',
        404
    );
}
// Se busca de lo más concreto a lo más general: sku exacto, luego el color
// del artículo y por último cualquier foto del artículo. Así una línea sin
// color, o con un color sin foto propia, sigue enseñando la del artículo.
$patrones = [];
if ($color !== '' && $indice !== '') {
    $patrones[] = nombre_base_foto($articulo, $color, $indice) .
        '_' . $resolucion . '.png';
}
if ($color !== '') {
    $patrones[] = $articulo . '_' . $color . '_*_' . $resolucion . '.png';
}
$patrones[] = $articulo . '_*_' . $resolucion . '.png';
$elegido = '';
foreach ($patrones as $patron) {
    $ficheros = glob($directorio . DIRECTORY_SEPARATOR . $patron);
    if ($ficheros === false) {
        $ficheros = [];
    }
    $ficheros = array_values(array_filter(
        $ficheros,
        static fn(string $fichero): bool =>
            fichero_bajo_directorio($fichero, $directorio)
    ));
    if ($ficheros !== []) {
        sort($ficheros, SORT_STRING);
        $elegido = $ficheros[0];
        break;
    }
}
if ($elegido === '') {
    responder_error(
        'FOTO_NO_ENCONTRADA',
        'No hay foto para el artículo solicitado.',
        404
    );
}
$tamano = filesize($elegido);
$modificado = filemtime($elegido);
if ($tamano === false || $modificado === false) {
    responder_error('FOTO_INVALIDA', 'No se pudo leer la foto.', 500);
}
$etag = '"' . md5(basename($elegido) . '|' . $tamano . '|' . $modificado) . '"';
$etagCliente = cabecera_http('If-None-Match');
header('Content-Type: image/png');
header('ETag: ' . $etag);
header('Last-Modified: ' . gmdate('D, d M Y H:i:s', $modificado) . ' GMT');
header('Cache-Control: private, max-age=86400');
header('X-Foto-Nombre: ' . basename($elegido));
if ($etagCliente !== '' && $etagCliente === $etag) {
    http_response_code(304);
    exit;
}
header('Content-Length: ' . $tamano);
readfile($elegido);
exit;
