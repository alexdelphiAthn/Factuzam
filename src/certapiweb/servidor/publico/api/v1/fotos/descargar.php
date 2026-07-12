<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/fotos.php';

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
$resolucionEntrada = $_GET['resolucion'] ?? 'real';
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
if ($indice !== '' && $color === '') {
    responder_error(
        'INDICE_SIN_COLOR',
        'Para indicar un índice también debe indicarse el color.',
        422
    );
}
$directorio = directorio_fotos_referencia($referencia, false);
if (!is_dir($directorio)) {
    responder_error(
        'FOTOS_NO_ENCONTRADAS',
        'La instalación todavía no tiene fotos en el servidor.',
        404
    );
}
if ($color !== '' && $indice !== '') {
    $patron = nombre_base_foto($articulo, $color, $indice) .
        '_' . $resolucion . '.png';
} elseif ($color !== '') {
    $patron = $articulo . '_' . $color . '_*_' .
        $resolucion . '.png';
} else {
    $patron = $articulo . '_*_' . $resolucion . '.png';
}
$ficheros = glob($directorio . DIRECTORY_SEPARATOR . $patron);
if ($ficheros === false) {
    $ficheros = [];
}
$ficheros = array_values(array_filter(
    $ficheros,
    static fn(string $fichero): bool =>
        fichero_bajo_directorio($fichero, $directorio)
));
sort($ficheros, SORT_STRING);
if ($ficheros === []) {
    responder_error(
        'FOTOS_NO_ENCONTRADAS',
        'No hay fotos para el artículo solicitado.',
        404
    );
}
if (!class_exists('ZipArchive')) {
    responder_error(
        'ZIP_NO_DISPONIBLE',
        'El servidor no dispone de la extensión ZIP.',
        500
    );
}
$rutaZip = tempnam(sys_get_temp_dir(), 'fzam_foto_');
if ($rutaZip === false) {
    responder_error(
        'ZIP_NO_DISPONIBLE',
        'No se pudo crear el archivo temporal.',
        500
    );
}
$zip = new ZipArchive();
if ($zip->open($rutaZip, ZipArchive::OVERWRITE) !== true) {
    @unlink($rutaZip);
    responder_error('ZIP_NO_DISPONIBLE', 'No se pudo crear el ZIP.', 500);
}
$incluidas = 0;
foreach ($ficheros as $fichero) {
    if ($zip->addFile($fichero, basename($fichero))) {
        $incluidas++;
    }
}
$zip->close();
if ($incluidas === 0) {
    @unlink($rutaZip);
    responder_error(
        'ZIP_VACIO',
        'No se pudo empaquetar ninguna foto.',
        500
    );
}
$tamano = filesize($rutaZip);
if ($tamano === false) {
    @unlink($rutaZip);
    responder_error('ZIP_INVALIDO', 'No se pudo leer el ZIP.', 500);
}
header('Content-Type: application/zip');
header('Content-Length: ' . $tamano);
header(
    'Content-Disposition: attachment; filename="' .
    $articulo . '_' . $resolucion . '.zip"'
);
header('X-Foto-Count: ' . $incluidas);
header('Cache-Control: private, no-store');
readfile($rutaZip);
@unlink($rutaZip);
exit;
