<?php
declare(strict_types=1);

require_once __DIR__ . '/autenticacion.php';

function exigir_referencia_sif(array $credencial, string $referencia): string
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
    if ($referenciaToken === '' ||
        !hash_equals($referenciaToken, $referencia)) {
        responder_error(
            'REFERENCIA_NO_AUTORIZADA',
            'La API no pertenece a la referencia indicada.',
            403
        );
    }
    return $referenciaToken;
}

function parametro_declaracion_sif(
    array $datos,
    string $nombre,
    int $maximo
): string {
    $valor = $datos[$nombre] ?? '';
    $valor = is_string($valor) ? trim($valor) : '';
    if ($valor === '' || strlen($valor) > $maximo ||
        preg_match('/^[A-Za-z0-9._-]+$/D', $valor) !== 1) {
        responder_error(
            'DATO_DECLARACION_INVALIDO',
            'El campo ' . $nombre . ' no es válido.',
            422
        );
    }
    return $valor;
}

function directorio_declaraciones_sif(): string
{
    if (defined('CFG_DECLARACIONES_SIF_DIRECTORIO')) {
        $configurado = constant('CFG_DECLARACIONES_SIF_DIRECTORIO');
        if (is_string($configurado) && trim($configurado) !== '') {
            return rtrim($configurado, '/\\');
        }
    }
    return __DIR__ . DIRECTORY_SEPARATOR . 'declaraciones_sif';
}

function catalogo_declaraciones_sif(): array
{
    $ruta = directorio_declaraciones_sif() . DIRECTORY_SEPARATOR .
        'catalogo.php';
    if (!is_file($ruta)) {
        responder_error(
            'CATALOGO_DECLARACIONES_NO_DISPONIBLE',
            'No está disponible el catálogo de declaraciones responsables.',
            500
        );
    }
    $catalogo = require $ruta;
    if (!is_array($catalogo)) {
        responder_error(
            'CATALOGO_DECLARACIONES_INVALIDO',
            'El catálogo de declaraciones responsables no es válido.',
            500
        );
    }
    return $catalogo;
}

function version_comparable_sif(string $version): string
{
    if (preg_match('/^\d+(?:\.\d+)*/D', $version, $coincidencia) !== 1) {
        return '';
    }
    return $coincidencia[0];
}

function codigo_declaracion_sif(string $versionDesde): string
{
    $codigo = preg_replace('/[^A-Za-z0-9]+/', '_', $versionDesde) ?? '';
    return trim($codigo, '_');
}

function seleccionar_declaracion_sif(
    string $codigoSif,
    string $version
): array {
    $catalogo = catalogo_declaraciones_sif();
    $declaraciones = $catalogo[$codigoSif] ?? [];
    $seleccionada = null;
    $versionComparable = version_comparable_sif($version);
    if (is_array($declaraciones)) {
        foreach ($declaraciones as $declaracion) {
            if (is_array($declaracion)) {
                $versionDesde = $declaracion['version_desde'] ?? '';
                $desdeComparable = is_string($versionDesde)
                    ? version_comparable_sif($versionDesde)
                    : '';
                if (is_string($versionDesde) && $versionDesde !== '' &&
                    $desdeComparable !== '' && $versionComparable !== '' &&
                    version_compare(
                        $versionComparable,
                        $desdeComparable,
                        '>='
                    )) {
                    $seleccionComparable = $seleccionada === null
                        ? ''
                        : version_comparable_sif(
                            (string)$seleccionada['version_desde']
                        );
                    if ($seleccionada === null || version_compare(
                        $desdeComparable,
                        $seleccionComparable,
                        '>'
                    )) {
                        $seleccionada = $declaracion;
                    }
                }
            }
        }
    }
    if (!is_array($seleccionada)) {
        responder_error(
            'DECLARACION_NO_DISPONIBLE',
            'No existe una declaración aplicable a la versión solicitada.',
            404
        );
    }
    return $seleccionada;
}

function ruta_plantilla_declaracion_sif(
    string $codigoSif,
    array $declaracion
): string {
    $versionDesde = $declaracion['version_desde'] ?? '';
    $versionDesde = is_string($versionDesde) ? trim($versionDesde) : '';
    $codigoDeclaracion = codigo_declaracion_sif($versionDesde);
    if ($codigoDeclaracion === '') {
        responder_error(
            'CATALOGO_DECLARACIONES_INVALIDO',
            'El catálogo contiene una versión de declaración no válida.',
            500
        );
    }
    $archivo = 'declaracion_' . $codigoDeclaracion . '.html';
    $directorio = directorio_declaraciones_sif();
    $ruta = $directorio . DIRECTORY_SEPARATOR . $codigoSif .
        DIRECTORY_SEPARATOR . $archivo;
    $rutaReal = realpath($ruta);
    $directorioReal = realpath($directorio);
    if ($rutaReal === false || $directorioReal === false) {
        responder_error(
            'DECLARACION_NO_DISPONIBLE',
            'No existe una declaración responsable para la versión solicitada.',
            404
        );
    }
    $prefijo = rtrim($directorioReal, DIRECTORY_SEPARATOR) .
        DIRECTORY_SEPARATOR;
    if (!is_file($rutaReal) || !str_starts_with($rutaReal, $prefijo)) {
        responder_error(
            'DECLARACION_NO_DISPONIBLE',
            'No existe una declaración responsable para la versión solicitada.',
            404
        );
    }
    return $rutaReal;
}

function leer_declaracion_sif(string $codigoSif, string $version): array
{
    $declaracion = seleccionar_declaracion_sif($codigoSif, $version);
    $ruta = ruta_plantilla_declaracion_sif($codigoSif, $declaracion);
    $tamano = filesize($ruta);
    if ($tamano === false || $tamano > 2097152) {
        responder_error(
            'DECLARACION_INVALIDA',
            'La declaración responsable no tiene un tamaño válido.',
            500
        );
    }
    $html = file_get_contents($ruta);
    if (!is_string($html) || trim($html) === '') {
        responder_error(
            'DECLARACION_INVALIDA',
            'No se pudo leer la declaración responsable.',
            500
        );
    }
    $patronSif = '/<meta\s+name=["\']sif-code["\']\s+' .
        'content=["\']' . preg_quote($codigoSif, '/') .
        '["\']\s*\/?>/i';
    $codigoDeclaracion = codigo_declaracion_sif(
        (string)$declaracion['version_desde']
    );
    $patronCodigo = '/<meta\s+name=["\']declaracion-code["\']\s+' .
        'content=["\']' . preg_quote($codigoDeclaracion, '/') .
        '["\']\s*\/?>/i';
    if (preg_match($patronSif, $html) !== 1 ||
        preg_match($patronCodigo, $html) !== 1 ||
        !str_contains($html, '{{VERSION_SIF}}')) {
        responder_error(
            'DECLARACION_INCOHERENTE',
            'La plantilla no corresponde al código de declaración indicado.',
            500
        );
    }
    $versionHtml = htmlspecialchars(
        $version,
        ENT_QUOTES | ENT_SUBSTITUTE,
        'UTF-8'
    );
    $html = str_replace('{{VERSION_SIF}}', $versionHtml, $html);
    return [
        'codigo' => $codigoDeclaracion,
        'version_desde' => (string)$declaracion['version_desde'],
        'html' => $html
    ];
}
