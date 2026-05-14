<?php
// ----------------------------------------------------------------------
// upload_foto.php
// Recibe una imagen vía POST multipart y genera 3 versiones (real/300/150)
// en cloud_storage/<carpeta_cliente>/, junto con su hash SHA1.
//
// Nombre final = ARTICULO_COLOR_INDICE   (p.ej. A1234_ROJO_1)
// Se aceptan dos formas de identificar la foto:
//   a) articulo + color + indice  (preferido)
//   b) nombre  (compatibilidad con la versión anterior)
// ----------------------------------------------------------------------

ini_set('display_errors', '0');
error_reporting(E_ALL & ~E_DEPRECATED);
header('Content-Type: application/json');

// ---------- 1. Validación de API key ----------
$apiKeyEsperada = 'k7Hq9mZ2pXvR4nL8'; // CAMBIAR en producción
if (($_SERVER['HTTP_X_API_KEY'] ?? '') !== $apiKeyEsperada) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'No autorizado.']);
    exit;
}

// ---------- 2. Método ----------
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Método no permitido.']);
    exit;
}

// ---------- 3. Parámetros ----------
$articuloRaw       = $_POST['articulo']        ?? '';
$colorRaw          = $_POST['color']           ?? '';
$indiceRaw         = $_POST['indice']          ?? '1';
$nombreRaw         = $_POST['nombre']          ?? '';
$carpetaClienteRaw = $_POST['carpeta_cliente'] ?? '';
$osha1Raw          = $_POST['osha1']           ?? '';   // SHA1 del archivo local original
$file              = $_FILES['imagen']         ?? null;

// Sanitizar osha1 (debe ser hex de 40 caracteres o vacío)
$osha1 = '';
if ($osha1Raw !== '' && preg_match('/^[0-9a-fA-F]{40}$/', $osha1Raw)) {
    $osha1 = strtolower($osha1Raw);
}

// Sanitizar carpeta_cliente
$carpetaCliente = preg_replace('/[^A-Za-z0-9_-]/', '_', $carpetaClienteRaw);
if ($carpetaCliente === '') {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Falta el parámetro carpeta_cliente.']);
    exit;
}

// Componer nombre: prioridad a articulo+color+indice
$articulo = preg_replace('/[^A-Za-z0-9_-]/', '_', $articuloRaw);
$color    = preg_replace('/[^A-Za-z0-9_-]/', '_', $colorRaw);
$indice   = preg_replace('/[^0-9]/',         '',  $indiceRaw);

if ($articulo !== '' && $color !== '' && $indice !== '') {
    $nombre = $articulo . '_' . $color . '_' . $indice;
} else {
    // Compatibilidad: 'nombre' directo
    $nombre = preg_replace('/[^A-Za-z0-9_-]/', '_', $nombreRaw);
}

if ($nombre === '') {
    http_response_code(400);
    echo json_encode([
        'status'  => 'error',
        'message' => 'Faltan parámetros: se requiere (articulo+color+indice) o (nombre).',
    ]);
    exit;
}

// Archivo recibido
if (!$file || $file['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Error al recibir la imagen.']);
    exit;
}

// ---------- 4. GD ----------
if (!extension_loaded('gd')) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Extensión GD no disponible.']);
    exit;
}

// ---------- 5. Carpeta destino ----------
$baseStorage = __DIR__ . DIRECTORY_SEPARATOR . 'cloud_storage';
$uploadDir   = $baseStorage . DIRECTORY_SEPARATOR . $carpetaCliente . DIRECTORY_SEPARATOR;

if (!is_dir($uploadDir)) {
    http_response_code(404);
    echo json_encode([
        'status'  => 'error',
        'message' => "La carpeta del cliente '$carpetaCliente' no existe."
    ]);
    exit;
}

// Defensa en profundidad
$baseAllowed = realpath($baseStorage);
$uploadReal  = realpath($uploadDir);
if ($baseAllowed === false || $uploadReal === false ||
    strpos($uploadReal, $baseAllowed) !== 0) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Ruta inválida.']);
    exit;
}

// ---------- 6. Función de procesamiento ----------
function procesarImagen(string $sourcePath, string $uploadDir,
                        string $baseName, string $suffix,
                        ?int $targetWidth = null): bool
{
    $info = @getimagesize($sourcePath);
    if (!$info) {
        return false;
    }

    $mime       = $info['mime'];
    $origWidth  = $info[0];
    $origHeight = $info[1];

    switch ($mime) {
        case 'image/jpeg': $image = @imagecreatefromjpeg($sourcePath); break;
        case 'image/png':  $image = @imagecreatefrompng($sourcePath);  break;
        case 'image/webp': $image = @imagecreatefromwebp($sourcePath); break;
        case 'image/gif':  $image = @imagecreatefromgif($sourcePath);  break;
        default: return false;
    }
    if (!$image) {
        return false;
    }

    if ($targetWidth && $origWidth > $targetWidth) {
        $newWidth  = $targetWidth;
        $newHeight = (int) floor($origHeight * ($targetWidth / $origWidth));
    } else {
        $newWidth  = $origWidth;
        $newHeight = $origHeight;
    }

    $newImage = imagecreatetruecolor($newWidth, $newHeight);
    imagealphablending($newImage, false);
    imagesavealpha($newImage, true);
    $transparent = imagecolorallocatealpha($newImage, 255, 255, 255, 127);
    imagefilledrectangle($newImage, 0, 0, $newWidth, $newHeight, $transparent);

    imagecopyresampled($newImage, $image, 0, 0, 0, 0,
                       $newWidth, $newHeight, $origWidth, $origHeight);

    $imgFileName  = "{$baseName}_{$suffix}.png";
    $sha1FileName = "{$baseName}_{$suffix}.sha1";
    $imgPath      = $uploadDir . $imgFileName;
    $sha1Path     = $uploadDir . $sha1FileName;

    $ok = imagepng($newImage, $imgPath, 8);
    imagedestroy($newImage);
    imagedestroy($image);

    if (!$ok) {
        return false;
    }

    $hash = sha1_file($imgPath);
    if ($hash === false || file_put_contents($sha1Path, $hash) === false) {
        return false;
    }

    return true;
}

// ---------- 7. Generar las tres versiones ----------
$errores = [];

if (!procesarImagen($file['tmp_name'], $uploadDir, $nombre, 'real', null)) {
    $errores[] = 'real';
}
if (!procesarImagen($file['tmp_name'], $uploadDir, $nombre, '300', 300)) {
    $errores[] = '300';
}
if (!procesarImagen($file['tmp_name'], $uploadDir, $nombre, '150', 150)) {
    $errores[] = '150';
}

// SHA1 final del archivo "_real" para que el cliente lo registre
$sha1Real = @sha1_file($uploadDir . $nombre . '_real.png');

// Guardar el SHA1 del original (si nos lo mandaron) en _real.osha1
if ($osha1 !== '' && count($errores) === 0) {
    @file_put_contents($uploadDir . $nombre . '_real.osha1', $osha1);
}

if (count($errores) === 0) {
    echo json_encode([
        'status'          => 'success',
        'message'         => "Imágenes de '$nombre' guardadas correctamente.",
        'carpeta_cliente' => $carpetaCliente,
        'articulo'        => $articulo,
        'color'           => $color,
        'indice'          => $indice,
        'nombre'          => $nombre,
        'sha1'            => $sha1Real ?: null,
        'osha1'           => $osha1 ?: null,
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'status'  => 'error',
        'message' => 'Error al procesar la imagen.',
        'detalle' => $errores,
    ]);
}
