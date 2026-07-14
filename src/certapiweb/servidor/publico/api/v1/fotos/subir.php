<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/fotos.php';

function cargar_imagen(string $ruta, string $mime): GdImage|false
{
    return match ($mime) {
        'image/jpeg' => @imagecreatefromjpeg($ruta),
        'image/png' => @imagecreatefrompng($ruta),
        'image/webp' => @imagecreatefromwebp($ruta),
        'image/gif' => @imagecreatefromgif($ruta),
        default => false
    };
}

function guardar_version_png(
    GdImage $origen,
    int $anchoOrigen,
    int $altoOrigen,
    ?int $anchoMaximo,
    string $rutaTemporal
): bool {
    $ancho = $anchoOrigen;
    $alto = $altoOrigen;
    if ($anchoMaximo !== null && $anchoOrigen > $anchoMaximo) {
        $ancho = $anchoMaximo;
        $alto = max(1, (int)floor(
            $altoOrigen * ($anchoMaximo / $anchoOrigen)
        ));
    }
    $destino = imagecreatetruecolor($ancho, $alto);
    if ($destino === false) {
        return false;
    }
    imagealphablending($destino, false);
    imagesavealpha($destino, true);
    $transparente = imagecolorallocatealpha(
        $destino,
        255,
        255,
        255,
        127
    );
    imagefilledrectangle(
        $destino,
        0,
        0,
        $ancho,
        $alto,
        $transparente
    );
    $copiada = imagecopyresampled(
        $destino,
        $origen,
        0,
        0,
        0,
        0,
        $ancho,
        $alto,
        $anchoOrigen,
        $altoOrigen
    );
    $guardada = $copiada && imagepng($destino, $rutaTemporal, 8);
    imagedestroy($destino);
    return $guardada;
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    header('Allow: POST');
    responder_error('METODO_NO_PERMITIDO', 'Método no permitido.', 405);
}
if (!extension_loaded('gd')) {
    responder_error(
        'GD_NO_DISPONIBLE',
        'El servidor no dispone de la extensión GD.',
        500
    );
}
$credencial = exigir_token_api('fotos:escribir');
$referencia = exigir_referencia_fotos(
    $credencial,
    referencia_entrada($_POST)
);
$articulo = parametro_foto($_POST, 'articulo');
$color = parametro_foto($_POST, 'color', false);
$indiceEntrada = $_POST['indice'] ?? '1';
$indice = is_string($indiceEntrada)
    ? preg_replace('/[^0-9]/', '', $indiceEntrada)
    : '';
if ($indice === '' || (int)$indice < 1 || (int)$indice > 9999) {
    responder_error(
        'INDICE_INVALIDO',
        'El índice debe estar comprendido entre 1 y 9999.',
        422
    );
}
$archivo = $_FILES['imagen'] ?? null;
if (!is_array($archivo) ||
    ($archivo['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    responder_error(
        'IMAGEN_AUSENTE',
        'No se ha recibido correctamente el archivo imagen.',
        422
    );
}
$rutaSubida = $archivo['tmp_name'] ?? '';
$tamano = $archivo['size'] ?? 0;
$maximo = defined('CFG_FOTOS_MAX_BYTES')
    ? (int)constant('CFG_FOTOS_MAX_BYTES')
    : 20 * 1024 * 1024;
if (!is_string($rutaSubida) || !is_uploaded_file($rutaSubida) ||
    !is_int($tamano) || $tamano < 1 || $tamano > $maximo) {
    responder_error(
        'IMAGEN_INVALIDA',
        'El archivo recibido no es válido o supera el tamaño permitido.',
        413
    );
}
$informacion = @getimagesize($rutaSubida);
if (!is_array($informacion)) {
    responder_error('IMAGEN_INVALIDA', 'El archivo no es una imagen.', 422);
}
$ancho = (int)($informacion[0] ?? 0);
$alto = (int)($informacion[1] ?? 0);
$mime = (string)($informacion['mime'] ?? '');
if ($ancho < 1 || $alto < 1 || $ancho > 16000 || $alto > 16000 ||
    !in_array(
        $mime,
        ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
        true
    )) {
    responder_error(
        'IMAGEN_INVALIDA',
        'El formato o las dimensiones de la imagen no son válidos.',
        422
    );
}
$origen = cargar_imagen($rutaSubida, $mime);
if ($origen === false) {
    responder_error('IMAGEN_INVALIDA', 'No se pudo leer la imagen.', 422);
}
$directorio = directorio_fotos_referencia($referencia, true);
$nombreBase = nombre_base_foto($articulo, $color, $indice);
$versiones = [
    'real' => null,
    '300' => 300,
    '150' => 150
];
$temporales = [];
$destinos = [];
try {
    foreach ($versiones as $resolucion => $anchoMaximo) {
        $temporal = tempnam($directorio, '.subida_');
        if ($temporal === false || !guardar_version_png(
            $origen,
            $ancho,
            $alto,
            $anchoMaximo,
            $temporal
        )) {
            throw new RuntimeException(
                'No se pudo generar la resolución ' . $resolucion . '.'
            );
        }
        $temporales[$resolucion] = $temporal;
        $destinos[$resolucion] = $directorio . DIRECTORY_SEPARATOR .
            $nombreBase . '_' . $resolucion . '.png';
    }
    foreach ($temporales as $resolucion => $temporal) {
        if (!rename($temporal, $destinos[$resolucion])) {
            throw new RuntimeException(
                'No se pudo publicar la resolución ' . $resolucion . '.'
            );
        }
        unset($temporales[$resolucion]);
    }
} catch (Throwable $error) {
    foreach ($temporales as $temporal) {
        @unlink($temporal);
    }
    registrar_error_servidor($error);
    responder_error(
        'ERROR_GUARDANDO_FOTO',
        'No se pudo guardar la foto.',
        500
    );
} finally {
    imagedestroy($origen);
}
$hash = hash_file('sha256', $destinos['real']);
responder_ok(
    [
        'referencia' => $referencia,
        'nombre' => $nombreBase,
        'resoluciones' => array_keys($versiones),
        'sha256_real' => $hash === false ? '' : $hash
    ],
    201
);
