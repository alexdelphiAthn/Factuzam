<?php
declare(strict_types=1);

require dirname(__DIR__) . '/privado/firma.php';

if (!function_exists('sodium_crypto_sign_keypair')) {
    fwrite(STDERR, "ERROR: la extensión Sodium no está disponible.\n");
    exit(1);
}

$par = sodium_crypto_sign_keypair();
$privada = sodium_crypto_sign_secretkey($par);
$publica = sodium_crypto_sign_publickey($par);
$timestamp = (string)time();
$nonce = base64url_codificar(random_bytes(16));
$cuerpo = '{"referencia":"PRUEBA","ambitos":["prueba:leer"]}';
$mensaje = mensaje_canonico_crear_api(
    $timestamp,
    $nonce,
    hash('sha256', $cuerpo)
);
$firma = sodium_crypto_sign_detached($mensaje, $privada);
$valida = verificar_firma_ed25519(
    base64url_codificar($publica),
    base64url_codificar($firma),
    $mensaje
);
$rechazaAlterado = !verificar_firma_ed25519(
    base64url_codificar($publica),
    base64url_codificar($firma),
    $mensaje . 'alterado'
);

if (!$valida || !$rechazaAlterado) {
    fwrite(STDERR, "ERROR: la prueba Ed25519 ha fallado.\n");
    exit(1);
}

fwrite(STDOUT, "OK: firma válida y alteración rechazada.\n");
