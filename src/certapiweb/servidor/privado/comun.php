<?php
declare(strict_types=1);

require __DIR__ . '/config.php';

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');

function id_peticion(): string
{
    static $id = null;
    if ($id === null) {
        $id = bin2hex(random_bytes(12));
    }
    return $id;
}

function db_api(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(
            CFG_DB_DSN,
            CFG_DB_USUARIO,
            CFG_DB_PASSWORD,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false
            ]
        );
    }
    return $pdo;
}

function responder_ok(array $datos, int $estado = 200): never
{
    http_response_code($estado);
    echo json_encode(
        [
            'ok' => true,
            'datos' => $datos,
            'id_peticion' => id_peticion()
        ],
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
    );
    exit;
}

function responder_error(
    string $codigo,
    string $mensaje,
    int $estado
): never {
    http_response_code($estado);
    echo json_encode(
        [
            'ok' => false,
            'error' => [
                'codigo' => $codigo,
                'mensaje' => $mensaje
            ],
            'id_peticion' => id_peticion()
        ],
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
    );
    exit;
}

function cabecera_http(string $nombre): string
{
    $clave = 'HTTP_' . strtoupper(str_replace('-', '_', $nombre));
    $valor = $_SERVER[$clave] ?? '';
    if ($valor === '' && strcasecmp($nombre, 'Authorization') === 0) {
        $valor = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    }
    if ($valor === '' && function_exists('getallheaders')) {
        foreach (getallheaders() as $cabecera => $contenido) {
            if (strcasecmp((string)$cabecera, $nombre) === 0) {
                $valor = $contenido;
            }
        }
    }
    return is_string($valor) ? trim($valor) : '';
}

function cuerpo_json_desde_texto(string $texto): array
{
    $datos = json_decode($texto, true);
    if (!is_array($datos)) {
        responder_error('JSON_INVALIDO', 'El cuerpo JSON no es válido.', 400);
    }
    return $datos;
}

function registrar_error_servidor(Throwable $error): void
{
    error_log(
        'CertApiWeb ' . id_peticion() . ' ' .
        get_class($error) . ': ' . $error->getMessage()
    );
}

function token_bearer(): string
{
    $autorizacion = cabecera_http('Authorization');
    if (preg_match('/^Bearer\s+([^\s]+)$/iD', $autorizacion, $m) === 1) {
        return $m[1];
    }
    $token = cabecera_http('X-API-Key');
    if ($token === '') {
        responder_error(
            'TOKEN_AUSENTE',
            'No se ha recibido una credencial API.',
            401
        );
    }
    return $token;
}
