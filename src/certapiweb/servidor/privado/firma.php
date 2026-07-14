<?php
declare(strict_types=1);

const ACCION_CREAR_API = 'FZAM-API-CREAR-V1';

function base64url_decodificar(string $valor): string
{
    if ($valor === '' || preg_match('/^[A-Za-z0-9_-]+$/D', $valor) !== 1) {
        throw new InvalidArgumentException('Base64URL no válido');
    }
    $base64 = strtr($valor, '-_', '+/');
    $resto = strlen($base64) % 4;
    if ($resto !== 0) {
        $base64 .= str_repeat('=', 4 - $resto);
    }
    $resultado = base64_decode($base64, true);
    if ($resultado === false) {
        throw new InvalidArgumentException('Base64URL no válido');
    }
    return $resultado;
}

function base64url_codificar(string $valor): string
{
    return rtrim(strtr(base64_encode($valor), '+/', '-_'), '=');
}

function mensaje_canonico_crear_api(
    string $timestamp,
    string $nonce,
    string $hashCuerpo
): string {
    return ACCION_CREAR_API . "\n" .
        $timestamp . "\n" .
        $nonce . "\n" .
        strtolower($hashCuerpo);
}

function verificar_firma_ed25519(
    string $clavePublicaBase64Url,
    string $firmaBase64Url,
    string $mensaje
): bool {
    if (!function_exists('sodium_crypto_sign_verify_detached')) {
        throw new RuntimeException('La extensión Sodium no está disponible');
    }
    $clavePublica = base64url_decodificar($clavePublicaBase64Url);
    $firma = base64url_decodificar($firmaBase64Url);
    if (strlen($clavePublica) !== SODIUM_CRYPTO_SIGN_PUBLICKEYBYTES) {
        return false;
    }
    if (strlen($firma) !== SODIUM_CRYPTO_SIGN_BYTES) {
        return false;
    }
    return sodium_crypto_sign_verify_detached(
        $firma,
        $mensaje,
        $clavePublica
    );
}
