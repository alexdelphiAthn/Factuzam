<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/traducciones.php';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
    header('Allow: GET');
    responder_error('METODO_NO_PERMITIDO', 'Método no permitido.', 405);
}

exigir_token_api('descargar:traducciones');
$idiomaEntrada = $_GET['idioma'] ?? '';
if (!is_string($idiomaEntrada)) {
    responder_error(
        'IDIOMA_INVALIDO',
        'El idioma debe enviarse como texto.',
        422
    );
}

try {
    $idioma = normalizar_idioma_traduccion($idiomaEntrada);
    $traduccion = obtener_traduccion($idioma);
    $archivos = archivos_traduccion($traduccion);
    $paquete = crear_paquete_traduccion($traduccion, $archivos);
} catch (Throwable $error) {
    registrar_error_servidor($error);
    responder_error(
        'TRADUCCION_NO_DISPONIBLE',
        'No se pudo preparar la traducción solicitada.',
        500
    );
}

header('Content-Type: application/zip');
header('Content-Length: ' . $paquete['tamano']);
header(
    'Content-Disposition: attachment; filename="' .
    $paquete['nombre'] . '"'
);
header('X-Traduccion-Idioma: ' . $traduccion['idioma']);
header('X-Traduccion-Version: ' . $traduccion['version']);
header('X-Traduccion-Contrato: ' . CONTRATO_TRADUCCIONES_VERSION);
header('X-Traduccion-Sha256: ' . $paquete['sha256']);
header('X-Traduccion-Sql-Count: ' . count($archivos));
header('Cache-Control: private, no-store');
readfile($paquete['ruta']);
@unlink($paquete['ruta']);
exit;
