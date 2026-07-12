<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/autenticacion.php';

function texto_sif(array $datos, string $nombre, int $maximo): string
{
    $valor = $datos[$nombre] ?? '';
    $valor = is_string($valor) ? trim($valor) : '';
    $valor = preg_replace('/\s+/u', ' ', $valor) ?? '';
    if ($valor === '' || strlen($valor) > $maximo ||
        preg_match('/[\x00-\x1F\x7F]/u', $valor) === 1) {
        responder_error(
            'DATO_SIF_INVALIDO',
            'El campo ' . $nombre . ' no es válido.',
            422
        );
    }
    return $valor;
}

function nif_sif(array $datos): string
{
    $nif = strtoupper(texto_sif($datos, 'nif', 20));
    $nif = preg_replace('/[^A-Z0-9]/', '', $nif) ?? '';
    if ($nif === '' || strlen($nif) > 20) {
        responder_error('NIF_INVALIDO', 'El NIF no es válido.', 422);
    }
    return $nif;
}

function generar_numero_instalacion(): string
{
    return 'FZ-' . strtoupper(bin2hex(random_bytes(12)));
}

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
$credencial = exigir_token_api('sif:instalacion');
$datos = cuerpo_json_desde_texto($cuerpo);
$referencia = texto_sif($datos, 'referencia', 100);
if (!hash_equals((string)$credencial['referencia'], $referencia)) {
    responder_error(
        'REFERENCIA_NO_AUTORIZADA',
        'La API no pertenece a la referencia indicada.',
        403
    );
}
$version = texto_sif($datos, 'version', 60);
$razonSocial = texto_sif($datos, 'razon_social', 200);
$nif = nif_sif($datos);
$codigoSif = strtoupper(texto_sif($datos, 'sif', 20));
if ($codigoSif !== 'FZ') {
    responder_error('SIF_NO_RECONOCIDO', 'El SIF no está autorizado.', 422);
}
$pdo = db_api();
try {
    $pdo->beginTransaction();
    $consulta = $pdo->prepare(
        'SELECT id, numero_instalacion FROM api_instalaciones_sif ' .
        'WHERE referencia = ? FOR UPDATE'
    );
    $consulta->execute([$referencia]);
    $instalacion = $consulta->fetch();
    $creada = false;
    if ($instalacion) {
        $numero = (string)$instalacion['numero_instalacion'];
        $actualizar = $pdo->prepare(
            'UPDATE api_instalaciones_sif SET version_actual = ?, ' .
            'razon_social_ultima = ?, nif_ultimo = ?, ' .
            'instante_modif = UTC_TIMESTAMP() WHERE id = ?'
        );
        $actualizar->execute([
            $version,
            $razonSocial,
            $nif,
            (int)$instalacion['id']
        ]);
    } else {
        $creada = true;
        $numero = generar_numero_instalacion();
        $insertar = $pdo->prepare(
            'INSERT INTO api_instalaciones_sif ' .
            '(referencia, numero_instalacion, codigo_sif, version_actual, ' .
            'razon_social_ultima, nif_ultimo, instante_alta, instante_modif) ' .
            'VALUES (?, ?, ?, ?, ?, ?, UTC_TIMESTAMP(), UTC_TIMESTAMP())'
        );
        $insertar->execute([
            $referencia,
            $numero,
            $codigoSif,
            $version,
            $razonSocial,
            $nif
        ]);
    }
    $pdo->commit();
} catch (Throwable $error) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    registrar_error_servidor($error);
    responder_error(
        'ERROR_INSTALACION_SIF',
        'No se pudo obtener el número de instalación SIF.',
        500
    );
}
responder_ok([
    'numero_instalacion' => $numero,
    'referencia' => $referencia,
    'version' => $version,
    'sif' => $codigoSif,
    'creada' => $creada
]);
