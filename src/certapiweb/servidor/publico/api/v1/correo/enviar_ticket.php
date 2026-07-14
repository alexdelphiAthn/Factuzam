<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/correo.php';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    header('Allow: POST');
    responder_error('METODO_NO_PERMITIDO', 'Método no permitido.', 405);
}
$credencial = exigir_token_api('correo:enviar');
$referencia = trim((string)($credencial['referencia'] ?? ''));
$referenciaEntrada = $_POST['referencia'] ?? '';
$destinatarioEntrada = $_POST['destinatario'] ?? '';
$operacionEntrada = $_POST['operacion'] ?? '';
$empresaEntrada = $_POST['nombre_empresa'] ?? '';
$destinatario = is_string($destinatarioEntrada)
    ? trim($destinatarioEntrada)
    : '';
$operacion = is_string($operacionEntrada) ? trim($operacionEntrada) : '';
$nombreEmpresa = is_string($empresaEntrada) ? trim($empresaEntrada) : '';
$referenciaPeticion = is_string($referenciaEntrada)
    ? trim($referenciaEntrada)
    : '';
if ($referenciaPeticion === '' ||
    !hash_equals($referencia, $referenciaPeticion)) {
    responder_error(
        'REFERENCIA_INVALIDA',
        'La referencia no corresponde con la credencial API.',
        403
    );
}
if (filter_var($destinatario, FILTER_VALIDATE_EMAIL) === false) {
    responder_error(
        'DESTINATARIO_INVALIDO',
        'La dirección de correo del destinatario no es válida.',
        422
    );
}
if ($operacion === '' || strlen($operacion) > 100 ||
    preg_match('/[\x00-\x1F\x7F]/', $operacion) === 1) {
    responder_error(
        'OPERACION_INVALIDA',
        'El número de operación no es válido.',
        422
    );
}
if ($nombreEmpresa === '' || strlen($nombreEmpresa) > 200 ||
    preg_match('/[\x00-\x1F\x7F]/', $nombreEmpresa) === 1) {
    responder_error(
        'EMPRESA_INVALIDA',
        'El nombre de empresa no es válido.',
        422
    );
}
$archivo = $_FILES['documentos'] ?? null;
if (!is_array($archivo)) {
    responder_error(
        'DOCUMENTOS_AUSENTES',
        'No se ha recibido ningún documento PDF.',
        422
    );
}
$documentos = documentos_pdf_subidos($archivo);
$asunto = 'OPERACION ' . $operacion . ' ' . $nombreEmpresa;
$cuerpo = 'Adjuntamos documentación ticket ' . $operacion . '.';
registrar_evento_correo(
    $referencia,
    'INICIO',
    'Operación ' . $operacion . '; documentos=' . count($documentos)
);
try {
    $configuracion = configuracion_smtp_referencia($referencia);
    enviar_documentacion_ticket(
        $configuracion,
        $destinatario,
        $asunto,
        $cuerpo,
        $documentos
    );
} catch (ConfiguracionCorreoException $error) {
    registrar_error_correo($error, $referencia, 'CONFIGURACION');
    responder_error(
        'CORREO_CONFIGURACION',
        $error->getMessage(),
        500
    );
} catch (DependenciaCorreoException $error) {
    registrar_error_correo($error, $referencia, 'DEPENDENCIA');
    responder_error(
        'CORREO_DEPENDENCIA',
        $error->getMessage(),
        500
    );
} catch (EnvioCorreoException $error) {
    registrar_error_correo(
        $error->getPrevious() ?? $error,
        $referencia,
        'SMTP'
    );
    responder_error(
        'CORREO_SMTP',
        'El servidor SMTP ha rechazado el envío. Revise el usuario, la ' .
        'contraseña y la cuenta de correo.',
        502
    );
} catch (Throwable $error) {
    registrar_error_correo($error, $referencia, 'INTERNO');
    responder_error(
        'CORREO_NO_ENVIADO',
        'Se produjo un error interno al preparar el correo.',
        502
    );
}
registrar_evento_correo(
    $referencia,
    'ENVIADO',
    'Operación ' . $operacion . '; documentos=' . count($documentos)
);
responder_ok([
    'operacion' => $operacion,
    'documentos' => count($documentos)
]);
