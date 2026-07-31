<?php
declare(strict_types=1);

require_once __DIR__ . '/autenticacion.php';

const CONTRATO_TRADUCCIONES_VERSION = 1;

function normalizar_idioma_traduccion(string $idioma): string
{
    $idioma = trim($idioma);
    $coincide = preg_match(
        '/^([a-z]{2,3})(?:[-_]([a-z]{2}))?$/iD',
        $idioma,
        $partes
    );
    if ($coincide !== 1) {
        responder_error(
            'IDIOMA_INVALIDO',
            'El idioma debe usar una etiqueta como zh-CN.',
            422
        );
    }
    $resultado = strtolower($partes[1]);
    if (isset($partes[2]) && $partes[2] !== '') {
        $resultado .= '-' . strtoupper($partes[2]);
    }
    return $resultado;
}

function catalogo_traducciones(): array
{
    $rutaCatalogo = CFG_TRADUCCIONES_DIRECTORIO .
        DIRECTORY_SEPARATOR . 'catalogo.php';
    if (!is_file($rutaCatalogo)) {
        throw new RuntimeException(
            'No se encuentra el catálogo privado de traducciones.'
        );
    }
    $catalogo = require $rutaCatalogo;
    if (!is_array($catalogo)) {
        throw new RuntimeException(
            'El catálogo privado de traducciones no es válido.'
        );
    }
    return $catalogo;
}

function obtener_traduccion(string $idioma): array
{
    $catalogo = catalogo_traducciones();
    $traduccion = $catalogo[$idioma] ?? null;
    if (!is_array($traduccion)) {
        responder_error(
            'TRADUCCION_NO_DISPONIBLE',
            'No hay una traducción disponible para el idioma solicitado.',
            404
        );
    }
    $nombre = $traduccion['nombre'] ?? null;
    $version = $traduccion['version'] ?? null;
    $archivos = $traduccion['archivos'] ?? null;
    if (!is_string($nombre) || $nombre === '' ||
        !is_int($version) || $version < 1 ||
        !is_array($archivos) || $archivos === []) {
        throw new RuntimeException(
            'La entrada del catálogo de traducciones no es válida.'
        );
    }
    $traduccion['idioma'] = $idioma;
    return $traduccion;
}

function ruta_contenida_en(string $ruta, string $directorio): bool
{
    $directorio = rtrim($directorio, DIRECTORY_SEPARATOR) .
        DIRECTORY_SEPARATOR;
    return str_starts_with($ruta, $directorio);
}

function archivos_traduccion(array $traduccion): array
{
    $directorioBase = realpath(CFG_TRADUCCIONES_DIRECTORIO);
    if ($directorioBase === false) {
        throw new RuntimeException(
            'No se encuentra el directorio privado de traducciones.'
        );
    }
    $directorioIdioma = realpath(
        $directorioBase . DIRECTORY_SEPARATOR . $traduccion['idioma']
    );
    if ($directorioIdioma === false ||
        !ruta_contenida_en($directorioIdioma, $directorioBase)) {
        throw new RuntimeException(
            'No se encuentra el directorio del idioma solicitado.'
        );
    }
    $resultado = [];
    $tamanoTotal = 0;
    foreach ($traduccion['archivos'] as $nombreArchivo) {
        if (!is_string($nombreArchivo) ||
            preg_match('/^[A-Za-z0-9][A-Za-z0-9._-]*\.sql$/D',
                $nombreArchivo) !== 1) {
            throw new RuntimeException(
                'El catálogo contiene un nombre de archivo no válido.'
            );
        }
        $ruta = realpath(
            $directorioIdioma . DIRECTORY_SEPARATOR . $nombreArchivo
        );
        if ($ruta === false || !is_file($ruta) ||
            !ruta_contenida_en($ruta, $directorioIdioma)) {
            throw new RuntimeException(
                'No se encuentra un SQL declarado en el catálogo.'
            );
        }
        $tamano = filesize($ruta);
        $huella = hash_file('sha256', $ruta);
        if ($tamano === false || $huella === false) {
            throw new RuntimeException(
                'No se pudo leer un SQL de traducción.'
            );
        }
        $tamanoTotal += $tamano;
        if ($tamanoTotal > CFG_TRADUCCIONES_MAX_BYTES) {
            responder_error(
                'TRADUCCION_DEMASIADO_GRANDE',
                'El paquete de traducción supera el tamaño permitido.',
                413
            );
        }
        $resultado[] = [
            'nombre' => $nombreArchivo,
            'ruta' => $ruta,
            'tamano' => $tamano,
            'sha256' => $huella
        ];
    }
    return $resultado;
}

function crear_paquete_traduccion(
    array $traduccion,
    array $archivos
): array {
    if (!class_exists('ZipArchive')) {
        responder_error(
            'ZIP_NO_DISPONIBLE',
            'El servidor no dispone de la extensión ZIP.',
            500
        );
    }
    $rutaZip = tempnam(sys_get_temp_dir(), 'fzam_trad_');
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
        responder_error(
            'ZIP_NO_DISPONIBLE',
            'No se pudo crear el paquete de traducción.',
            500
        );
    }
    $archivosManifiesto = [];
    $paqueteValido = true;
    foreach ($archivos as $archivo) {
        if (!$zip->addFile($archivo['ruta'], $archivo['nombre'])) {
            $paqueteValido = false;
        }
        $archivosManifiesto[] = [
            'nombre' => $archivo['nombre'],
            'tamano' => $archivo['tamano'],
            'sha256' => $archivo['sha256']
        ];
    }
    $manifiesto = json_encode(
        [
            'version_contrato' => CONTRATO_TRADUCCIONES_VERSION,
            'idioma' => $traduccion['idioma'],
            'nombre' => $traduccion['nombre'],
            'version' => $traduccion['version'],
            'archivos' => $archivosManifiesto
        ],
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES |
        JSON_PRETTY_PRINT
    );
    if ($manifiesto === false ||
        !$zip->addFromString('manifiesto.json', $manifiesto)) {
        $paqueteValido = false;
    }
    $zip->close();
    if (!$paqueteValido) {
        @unlink($rutaZip);
        responder_error(
            'ZIP_INVALIDO',
            'No se pudo completar el paquete de traducción.',
            500
        );
    }
    $tamano = filesize($rutaZip);
    $huella = hash_file('sha256', $rutaZip);
    if ($tamano === false || $huella === false) {
        @unlink($rutaZip);
        responder_error(
            'ZIP_INVALIDO',
            'No se pudo leer el paquete de traducción.',
            500
        );
    }
    return [
        'ruta' => $rutaZip,
        'nombre' => 'factuzam_traduccion_' . $traduccion['idioma'] .
            '_v' . $traduccion['version'] . '.zip',
        'tamano' => $tamano,
        'sha256' => $huella
    ];
}
