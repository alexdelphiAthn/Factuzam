<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

function responder(int $codigo, array $datos): void
{
    http_response_code($codigo);
    echo json_encode($datos, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function limpiar_texto($valor): string
{
    if (!is_string($valor)) {
        return '';
    }
    $valor = trim($valor);
    $valor = preg_replace('/\s+/u', ' ', $valor);
    return $valor ?? '';
}

function limpiar_nif($valor): string
{
    $valor = strtoupper(limpiar_texto($valor));
    return preg_replace('/[^A-Z0-9]/', '', $valor) ?? '';
}

function generar_numero_instalacion(string $sif): string
{
    $aleatorio = strtoupper(bin2hex(random_bytes(6)));
    return $sif . '-' . gmdate('Ymd') . '-' . $aleatorio;
}

function ruta_privada_log(): string
{
    return dirname(__DIR__, 2) . '/instalaciones_sif.log';
}

function ruta_privada_datos(): string
{
    return dirname(__DIR__, 2) . '/instalaciones_sif.json';
}

function guardar_log_instalacion(array $datos): void
{
    $archivo = ruta_privada_log();
    $dir = dirname($archivo);
    if (!is_dir($dir) && !mkdir($dir, 0750, true)) {
        responder(500, [
            'ok' => false,
            'message' => 'No se pudo crear el directorio privado de log'
        ]);
    }
    $linea = json_encode($datos, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    if ($linea === false) {
        responder(500, [
            'ok' => false,
            'message' => 'No se pudo serializar el log de instalacion'
        ]);
    }
    $bytes = file_put_contents($archivo, $linea . PHP_EOL, FILE_APPEND | LOCK_EX);
    if ($bytes === false) {
        responder(500, [
            'ok' => false,
            'message' => 'No se pudo escribir el log de instalacion'
        ]);
    }
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    responder(405, [
        'ok' => false,
        'message' => 'Metodo no permitido'
    ]);
}

$entrada = file_get_contents('php://input');
$datos = json_decode($entrada ?: '', true);
if (!is_array($datos)) {
    responder(400, [
        'ok' => false,
        'message' => 'JSON no valido'
    ]);
}

$version = limpiar_texto($datos['version'] ?? '');
$razonSocial = limpiar_texto($datos['razon_social'] ?? '');
$nif = limpiar_nif($datos['nif'] ?? '');
$sif = strtoupper(limpiar_texto($datos['sif'] ?? ''));

if ($version === '' || $razonSocial === '' || $nif === '' || $sif === '') {
    responder(400, [
        'ok' => false,
        'message' => 'Faltan version, razon_social, nif o sif'
    ]);
}

if ($sif !== 'FZ') {
    responder(400, [
        'ok' => false,
        'message' => 'SIF no reconocido'
    ]);
}

$dirDatos = dirname(ruta_privada_datos());
if (!is_dir($dirDatos) && !mkdir($dirDatos, 0750, true)) {
    responder(500, [
        'ok' => false,
        'message' => 'No se pudo crear el almacen del servicio'
    ]);
}

$archivo = ruta_privada_datos();
$fp = fopen($archivo, 'c+');
if ($fp === false) {
    responder(500, [
        'ok' => false,
        'message' => 'No se pudo abrir el almacen del servicio'
    ]);
}

try {
    if (!flock($fp, LOCK_EX)) {
        responder(500, [
            'ok' => false,
            'message' => 'No se pudo bloquear el almacen del servicio'
        ]);
    }
    $contenido = stream_get_contents($fp);
    $base = json_decode($contenido ?: '{}', true);
    if (!is_array($base)) {
        $base = [];
    }
    if (!isset($base['instalaciones']) || !is_array($base['instalaciones'])) {
        $base['instalaciones'] = [];
    }
    $clave = hash('sha256', $sif . '|' . $nif . '|' . $version);
    $accion = 'reutilizada';
    if (!isset($base['instalaciones'][$clave])) {
        $accion = 'nueva';
        $base['instalaciones'][$clave] = [
            'numero_instalacion' => generar_numero_instalacion($sif),
            'version' => $version,
            'razon_social' => $razonSocial,
            'nif' => $nif,
            'sif' => $sif,
            'created_at' => gmdate('c'),
            'updated_at' => gmdate('c')
        ];
    } else {
        $base['instalaciones'][$clave]['razon_social'] = $razonSocial;
        $base['instalaciones'][$clave]['updated_at'] = gmdate('c');
    }
    rewind($fp);
    ftruncate($fp, 0);
    fwrite($fp, json_encode($base, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    fflush($fp);
    $registro = $base['instalaciones'][$clave];
} finally {
    flock($fp, LOCK_UN);
    fclose($fp);
}

guardar_log_instalacion([
    'timestamp' => gmdate('c'),
    'accion' => $accion,
    'numero_instalacion' => $registro['numero_instalacion'],
    'version' => $registro['version'],
    'razon_social' => $razonSocial,
    'nif' => $registro['nif'],
    'sif' => $registro['sif'],
    'ip' => $_SERVER['REMOTE_ADDR'] ?? '',
    'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? '',
    'clave' => $clave
]);

responder(200, [
    'ok' => true,
    'numero_instalacion' => $registro['numero_instalacion'],
    'version' => $registro['version'],
    'nif' => $registro['nif'],
    'sif' => $registro['sif']
]);
