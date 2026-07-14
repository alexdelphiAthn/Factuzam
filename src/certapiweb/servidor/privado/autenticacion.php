<?php
declare(strict_types=1);

require_once __DIR__ . '/comun.php';
require_once __DIR__ . '/firma.php';

function validar_firma_emisora(string $cuerpo): array
{
    $idClave = cabecera_http('X-FZ-Key-Id');
    $timestamp = cabecera_http('X-FZ-Timestamp');
    $nonce = cabecera_http('X-FZ-Nonce');
    $firma = cabecera_http('X-FZ-Signature');
    if ($idClave === '' || $timestamp === '' ||
        $nonce === '' || $firma === '') {
        responder_error(
            'FIRMA_INCOMPLETA',
            'Faltan cabeceras de autenticación.',
            401
        );
    }
    if (!ctype_digit($timestamp)) {
        responder_error('TIMESTAMP_INVALIDO', 'Timestamp no válido.', 401);
    }
    if (abs(time() - (int)$timestamp) > CFG_DESFASE_MAXIMO_SEGUNDOS) {
        responder_error(
            'FIRMA_CADUCADA',
            'La petición firmada ha caducado.',
            401
        );
    }
    if (preg_match('/^[A-Za-z0-9_-]{16,128}$/D', $nonce) !== 1) {
        responder_error('NONCE_INVALIDO', 'Nonce no válido.', 401);
    }
    $clavePublica = CFG_CLAVES_EMISORAS[$idClave] ?? null;
    if (!is_string($clavePublica) || $clavePublica === '') {
        responder_error('EMISOR_DESCONOCIDO', 'Emisor no autorizado.', 401);
    }
    $mensaje = mensaje_canonico_crear_api(
        $timestamp,
        $nonce,
        hash('sha256', $cuerpo)
    );
    try {
        $valida = verificar_firma_ed25519($clavePublica, $firma, $mensaje);
    } catch (Throwable $error) {
        registrar_error_servidor($error);
        responder_error('FIRMA_INVALIDA', 'La firma no es válida.', 401);
    }
    if (!$valida) {
        responder_error('FIRMA_INVALIDA', 'La firma no es válida.', 401);
    }
    return [
        'id_clave' => $idClave,
        'nonce' => $nonce,
        'timestamp' => (int)$timestamp
    ];
}

function registrar_nonce(PDO $pdo, string $idClave, string $nonce): void
{
    $limpiar = $pdo->prepare(
        'DELETE FROM api_nonces_admin ' .
        'WHERE instante_alta < DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 DAY)'
    );
    $limpiar->execute();
    $insertar = $pdo->prepare(
        'INSERT INTO api_nonces_admin ' .
        '(id_clave, nonce, instante_alta) ' .
        'VALUES (?, ?, UTC_TIMESTAMP())'
    );
    try {
        $insertar->execute([$idClave, $nonce]);
    } catch (PDOException $error) {
        if ($error->getCode() === '23000') {
            responder_error(
                'PETICION_REPETIDA',
                'La petición firmada ya se ha utilizado.',
                409
            );
        }
        throw $error;
    }
}

function validar_ambitos(array $ambitos): array
{
    $resultado = [];
    foreach ($ambitos as $ambito) {
        if (!is_string($ambito)) {
            responder_error(
                'AMBITO_INVALIDO',
                'Todos los ámbitos deben ser texto.',
                422
            );
        }
        $ambito = trim($ambito);
        if (!in_array($ambito, CFG_AMBITOS_PERMITIDOS, true)) {
            responder_error(
                'AMBITO_NO_PERMITIDO',
                'El ámbito solicitado no está permitido: ' . $ambito,
                403
            );
        }
        if (!in_array($ambito, $resultado, true)) {
            $resultado[] = $ambito;
        }
    }
    if ($resultado === []) {
        responder_error(
            'AMBITOS_VACIOS',
            'Debe indicarse al menos un ámbito.',
            422
        );
    }
    sort($resultado, SORT_STRING);
    return $resultado;
}

function exigir_token_api(string $ambitoRequerido): array
{
    $token = token_bearer();
    if (strlen($token) < 32 || strlen($token) > 128) {
        responder_error('TOKEN_INVALIDO', 'La credencial no es válida.', 401);
    }
    $hash = hash('sha256', $token);
    $consulta = db_api()->prepare(
        'SELECT id, referencia, ambitos, estado ' .
        'FROM api_credenciales ' .
        'WHERE token_hash = ? LIMIT 1'
    );
    $consulta->execute([$hash]);
    $credencial = $consulta->fetch();
    if (!$credencial || $credencial['estado'] !== 'ACTIVA') {
        responder_error('TOKEN_INVALIDO', 'La credencial no es válida.', 401);
    }
    $ambitos = json_decode((string)$credencial['ambitos'], true);
    if (!is_array($ambitos) ||
        !in_array($ambitoRequerido, $ambitos, true)) {
        responder_error(
            'PERMISO_INSUFICIENTE',
            'La credencial no permite esta operación.',
            403
        );
    }
    $actualizar = db_api()->prepare(
        'UPDATE api_credenciales ' .
        'SET instante_ultimo_uso = UTC_TIMESTAMP() WHERE id = ?'
    );
    $actualizar->execute([(int)$credencial['id']]);
    $credencial['ambitos_decodificados'] = $ambitos;
    return $credencial;
}
