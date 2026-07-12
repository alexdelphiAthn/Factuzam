<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/autenticacion.php';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    header('Allow: POST');
    responder_error('METODO_NO_PERMITIDO', 'Método no permitido.', 405);
}

$cuerpo = file_get_contents('php://input');
if (!is_string($cuerpo) || $cuerpo === '') {
    responder_error('CUERPO_VACIO', 'No se ha recibido contenido.', 400);
}
if (strlen($cuerpo) > 32768) {
    responder_error('CUERPO_GRANDE', 'La petición es demasiado grande.', 413);
}

$emisor = validar_firma_emisora($cuerpo);
$datos = cuerpo_json_desde_texto($cuerpo);
$referencia = isset($datos['referencia']) && is_string($datos['referencia'])
    ? trim($datos['referencia'])
    : '';
$ambitosEntrada = $datos['ambitos'] ?? null;

if ($referencia === '' || strlen($referencia) > 100 ||
    preg_match('/[\x00-\x1F\x7F]/u', $referencia) === 1) {
    responder_error(
        'REFERENCIA_INVALIDA',
        'La referencia debe contener entre 1 y 100 caracteres.',
        422
    );
}
if (!is_array($ambitosEntrada)) {
    responder_error(
        'AMBITOS_INVALIDOS',
        'Los ámbitos deben enviarse como una lista.',
        422
    );
}
$ambitos = validar_ambitos($ambitosEntrada);
$token = CFG_PREFIJO_TOKEN . base64url_codificar(random_bytes(32));
$hashToken = hash('sha256', $token);
$prefijoToken = substr($token, 0, 16);
$pdo = db_api();

try {
    $pdo->beginTransaction();
    registrar_nonce($pdo, $emisor['id_clave'], $emisor['nonce']);
    $insertar = $pdo->prepare(
        'INSERT INTO api_credenciales ' .
        '(referencia, token_hash, token_prefijo, ambitos, id_clave_emisora, ' .
        'estado, instante_alta) ' .
        'VALUES (?, ?, ?, ?, ?, "ACTIVA", UTC_TIMESTAMP())'
    );
    $insertar->execute([
        $referencia,
        $hashToken,
        $prefijoToken,
        json_encode($ambitos, JSON_UNESCAPED_UNICODE),
        $emisor['id_clave']
    ]);
    $idApi = (int)$pdo->lastInsertId();
    $pdo->commit();
} catch (PDOException $error) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    if ($error->getCode() === '23000') {
        responder_error(
            'REFERENCIA_EXISTENTE',
            'Ya existe una credencial con esa referencia.',
            409
        );
    }
    registrar_error_servidor($error);
    responder_error('ERROR_INTERNO', 'No se pudo crear la credencial.', 500);
} catch (Throwable $error) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    registrar_error_servidor($error);
    responder_error('ERROR_INTERNO', 'No se pudo crear la credencial.', 500);
}

responder_ok(
    [
        'id_api' => $idApi,
        'referencia' => $referencia,
        'ambitos' => $ambitos,
        'token' => $token,
        'token_mostrado_una_vez' => true
    ],
    201
);
