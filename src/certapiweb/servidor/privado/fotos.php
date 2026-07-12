<?php
declare(strict_types=1);

require_once __DIR__ . '/autenticacion.php';

function exigir_referencia_fotos(array $credencial, string $referencia): string
{
    $referencia = trim($referencia);
    $referenciaToken = trim((string)($credencial['referencia'] ?? ''));
    if ($referencia === '' || strlen($referencia) > 100) {
        responder_error(
            'REFERENCIA_INVALIDA',
            'La referencia global de la instalación no es válida.',
            422
        );
    }
    if ($referenciaToken === '' || !hash_equals($referenciaToken, $referencia)) {
        responder_error(
            'REFERENCIA_NO_AUTORIZADA',
            'La API no pertenece a la referencia indicada.',
            403
        );
    }
    return $referenciaToken;
}

function directorio_base_fotos(): string
{
    if (defined('CFG_FOTOS_DIRECTORIO')) {
        $configurado = constant('CFG_FOTOS_DIRECTORIO');
        if (is_string($configurado) && trim($configurado) !== '') {
            return rtrim($configurado, '/\\');
        }
    }
    return __DIR__ . DIRECTORY_SEPARATOR . 'datos' .
        DIRECTORY_SEPARATOR . 'fotos';
}

function directorio_fotos_referencia(
    string $referencia,
    bool $crear
): string {
    $base = directorio_base_fotos();
    if ($crear && !is_dir($base) && !mkdir($base, 0750, true) &&
        !is_dir($base)) {
        responder_error(
            'ALMACEN_NO_DISPONIBLE',
            'No se pudo preparar el almacén de fotos.',
            500
        );
    }
    $directorio = $base . DIRECTORY_SEPARATOR . hash('sha256', $referencia);
    if ($crear && !is_dir($directorio) &&
        !mkdir($directorio, 0750, true) && !is_dir($directorio)) {
        responder_error(
            'ALMACEN_NO_DISPONIBLE',
            'No se pudo preparar el almacén de la instalación.',
            500
        );
    }
    return $directorio;
}

function sanear_segmento_foto(string $valor): string
{
    $valor = trim($valor);
    $valor = preg_replace('/[^A-Za-z0-9_-]/', '_', $valor) ?? '';
    return trim($valor, '_-');
}

function parametro_foto(
    array $origen,
    string $nombre,
    bool $obligatorio = true
): string {
    $valor = $origen[$nombre] ?? '';
    $valor = is_string($valor) ? sanear_segmento_foto($valor) : '';
    if ($obligatorio && $valor === '') {
        responder_error(
            'PARAMETRO_INVALIDO',
            'Falta el parámetro ' . $nombre . '.',
            422
        );
    }
    if (strlen($valor) > 100) {
        responder_error(
            'PARAMETRO_INVALIDO',
            'El parámetro ' . $nombre . ' es demasiado largo.',
            422
        );
    }
    return $valor;
}

function referencia_entrada(array $origen): string
{
    $valor = $origen['referencia'] ?? '';
    return is_string($valor) ? trim($valor) : '';
}

function fichero_bajo_directorio(string $fichero, string $directorio): bool
{
    $rutaFichero = realpath($fichero);
    $rutaDirectorio = realpath($directorio);
    if ($rutaFichero === false || $rutaDirectorio === false) {
        return false;
    }
    $prefijo = rtrim($rutaDirectorio, DIRECTORY_SEPARATOR) .
        DIRECTORY_SEPARATOR;
    return is_file($rutaFichero) && str_starts_with($rutaFichero, $prefijo);
}

function nombre_base_foto(
    string $articulo,
    string $color,
    string $indice
): string {
    if ($color === '') {
        $color = 'GENERAL';
    }
    return $articulo . '_' . $color . '_' . $indice;
}
