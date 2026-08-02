<?php
declare(strict_types=1);

const ESTADOS_ERROR = [
    'NUEVO',
    'EN_REVISION',
    'ESPERANDO_CLIENTE',
    'RESPONDIDO',
    'RESUELTO',
    'CERRADO',
];

function variable_entorno(string $nombre, string $defecto = ''): string
{
    $valor = getenv($nombre);
    return $valor === false ? $defecto : trim((string)$valor);
}

function bbdd(): PDO
{
    static $conexion = null;
    if ($conexion instanceof PDO) {
        return $conexion;
    }
    $dsn = variable_entorno('FACTUZAM_ERROR_DSN');
    if ($dsn === '') {
        throw new RuntimeException('Falta configurar la BBDD de errores.');
    }
    $conexion = new PDO(
        $dsn,
        variable_entorno('FACTUZAM_ERROR_DB_USER'),
        variable_entorno('FACTUZAM_ERROR_DB_PASS'),
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
    $conexion->exec("SET time_zone = '+00:00'");
    return $conexion;
}

function responder_json(int $codigo, array $datos): void
{
    http_response_code($codigo);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo json_encode(
        $datos,
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
    );
    exit;
}

function limpiar_texto($valor, int $maximo): string
{
    if (!is_string($valor)) {
        return '';
    }
    $texto = trim(str_replace("\0", '', $valor));
    if (strlen($texto) > $maximo) {
        $texto = substr($texto, 0, $maximo);
    }
    return $texto;
}

function valor_sn($valor): string
{
    return strtoupper(limpiar_texto($valor, 1)) === 'S' ? 'S' : 'N';
}

function generar_referencia_error(): string
{
    return 'ERR-' . gmdate('Ymd-His') . '-' .
        strtoupper(bin2hex(random_bytes(4)));
}

function generar_token_seguimiento(): string
{
    return rtrim(strtr(base64_encode(random_bytes(32)), '+/', '-_'), '=');
}

function hash_token(string $token): string
{
    return hash('sha256', $token);
}

function ruta_almacen_privado(): string
{
    $ruta = variable_entorno('FACTUZAM_ERROR_STORAGE');
    if ($ruta === '') {
        $ruta = dirname(__DIR__, 2) . '/factuzam_error_storage';
    }
    return rtrim($ruta, DIRECTORY_SEPARATOR);
}

function asegurar_directorio(string $ruta): void
{
    if (!is_dir($ruta) && !mkdir($ruta, 0750, true) && !is_dir($ruta)) {
        throw new RuntimeException('No se pudo crear el almacén privado.');
    }
}

function url_publica_base(): string
{
    $configurada = variable_entorno('FACTUZAM_ERROR_PUBLIC_URL');
    if ($configurada !== '') {
        return rtrim($configurada, '/');
    }
    $https = ($_SERVER['HTTPS'] ?? '') !== '' &&
        ($_SERVER['HTTPS'] ?? '') !== 'off';
    $esquema = $https ? 'https' : 'http';
    $host = (string)($_SERVER['HTTP_HOST'] ?? 'localhost');
    if (!preg_match('/^[A-Za-z0-9.-]+(?::[0-9]+)?$/', $host)) {
        $host = 'localhost';
    }
    return $esquema . '://' . $host;
}

function url_seguimiento(string $referencia, string $token): string
{
    return url_publica_base() . '/error_seguimiento.php?' .
        http_build_query([
            'referencia' => $referencia,
            'token' => $token,
        ]);
}

function escapar(?string $texto): string
{
    return htmlspecialchars($texto ?? '', ENT_QUOTES, 'UTF-8');
}

function exigir_admin(): string
{
    $usuarioEsperado = variable_entorno('FACTUZAM_ERROR_ADMIN_USER');
    $claveEsperada = variable_entorno('FACTUZAM_ERROR_ADMIN_PASS');
    if ($usuarioEsperado === '' || $claveEsperada === '') {
        http_response_code(503);
        exit('La consola de errores no está configurada.');
    }
    $usuario = (string)($_SERVER['PHP_AUTH_USER'] ?? '');
    $clave = (string)($_SERVER['PHP_AUTH_PW'] ?? '');
    if (!hash_equals($usuarioEsperado, $usuario) ||
        !hash_equals($claveEsperada, $clave)) {
        header('WWW-Authenticate: Basic realm="Errores Factuzam"');
        http_response_code(401);
        exit('Autenticación requerida.');
    }
    return $usuario;
}

function iniciar_sesion_segura(): void
{
    if (session_status() !== PHP_SESSION_ACTIVE) {
        session_set_cookie_params([
            'httponly' => true,
            'secure' => (!empty($_SERVER['HTTPS']) &&
                $_SERVER['HTTPS'] !== 'off'),
            'samesite' => 'Strict',
        ]);
        session_start();
    }
}

function token_csrf(): string
{
    iniciar_sesion_segura();
    if (!isset($_SESSION['csrf_error'])) {
        $_SESSION['csrf_error'] = bin2hex(random_bytes(24));
    }
    return (string)$_SESSION['csrf_error'];
}

function validar_csrf(string $token): void
{
    $esperado = token_csrf();
    if (!hash_equals($esperado, $token)) {
        http_response_code(400);
        exit('Petición no válida.');
    }
}

function estado_valido(string $estado): bool
{
    return in_array($estado, ESTADOS_ERROR, true);
}

function registrar_estado(
    PDO $db,
    int $idError,
    ?string $anterior,
    string $nuevo,
    string $usuario,
    string $observaciones = ''
): void {
    if (!estado_valido($nuevo)) {
        throw new InvalidArgumentException('Estado no válido.');
    }
    $sql = 'INSERT INTO soporte_error_estados ' .
        '(ID_ERROR, ESTADO_ANTERIOR, ESTADO_NUEVO, ' .
        'OBSERVACIONES_ESTADO, USUARIO_ALTA, USUARIO_MODIF) ' .
        'VALUES (:id, :anterior, :nuevo, :observaciones, :usuario, :usuario)';
    $consulta = $db->prepare($sql);
    $consulta->execute([
        ':id' => $idError,
        ':anterior' => $anterior,
        ':nuevo' => $nuevo,
        ':observaciones' => $observaciones,
        ':usuario' => $usuario,
    ]);
}

function enviar_correo(
    string $destino,
    string $asunto,
    string $mensaje
): bool {
    if ($destino === '' || !filter_var($destino, FILTER_VALIDATE_EMAIL)) {
        return false;
    }
    $remitente = variable_entorno(
        'FACTUZAM_ERROR_FROM',
        'soporte@localhost'
    );
    $cabeceras = [
        'Content-Type: text/plain; charset=UTF-8',
        'From: ' . str_replace(["\r", "\n"], '', $remitente),
    ];
    return @mail(
        $destino,
        str_replace(["\r", "\n"], '', $asunto),
        $mensaje,
        implode("\r\n", $cabeceras)
    );
}

function notificar_desarrollador(
    string $referencia,
    string $resumen
): bool {
    $destino = variable_entorno('FACTUZAM_ERROR_DEVELOPER_EMAIL');
    return enviar_correo(
        $destino,
        'Nuevo error Factuzam ' . $referencia,
        $resumen
    );
}

function obtener_error_seguimiento(
    PDO $db,
    string $referencia,
    string $token
): ?array {
    $sql = 'SELECT * FROM soporte_errores ' .
        'WHERE REFERENCIA_ERROR = :referencia ' .
        'AND TOKEN_SEGUIMIENTO_HASH = :token';
    $consulta = $db->prepare($sql);
    $consulta->execute([
        ':referencia' => $referencia,
        ':token' => hash_token($token),
    ]);
    $error = $consulta->fetch();
    return is_array($error) ? $error : null;
}

function comunicaciones_error(PDO $db, int $idError): array
{
    $sql = 'SELECT * FROM soporte_error_comunicaciones ' .
        'WHERE ID_ERROR = :id ORDER BY INSTANTE_ALTA, ID_COMUNICACION';
    $consulta = $db->prepare($sql);
    $consulta->execute([':id' => $idError]);
    return $consulta->fetchAll();
}
