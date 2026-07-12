<?php
declare(strict_types=1);

require dirname(__DIR__) . '/privado/firma.php';

$ruta = $argv[1] ?? '-';
if ($ruta === '-') {
    $texto = stream_get_contents(STDIN);
} elseif (is_file($ruta)) {
    $texto = file_get_contents($ruta);
} else {
    fwrite(
        STDERR,
        "Uso: php prueba_interoperabilidad.php [vector.json|-]\n"
    );
    exit(1);
}
$vector = json_decode(is_string($texto) ? $texto : '', true);
if (!is_array($vector)) {
    fwrite(STDERR, "ERROR: el vector no contiene JSON válido.\n");
    exit(1);
}

try {
    $mensaje = base64url_decodificar((string)($vector['mensaje'] ?? ''));
    $firma = isset($vector['firma'])
        ? (string)$vector['firma']
        : (string)($vector['firma_1'] ?? '') .
            (string)($vector['firma_2'] ?? '');
    $valida = verificar_firma_ed25519(
        (string)($vector['clave_publica'] ?? ''),
        $firma,
        $mensaje
    );
} catch (Throwable $error) {
    fwrite(STDERR, 'ERROR: ' . $error->getMessage() . "\n");
    exit(1);
}

if (!$valida) {
    fwrite(STDERR, "ERROR: PHP ha rechazado la firma de Delphi.\n");
    exit(1);
}

fwrite(STDOUT, "OK: PHP ha verificado la firma creada por Delphi.\n");
