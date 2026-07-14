<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/declaraciones_sif.php';

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
$referenciaEntrada = $datos['referencia'] ?? '';
$referenciaEntrada = is_string($referenciaEntrada)
    ? $referenciaEntrada
    : '';
$referencia = exigir_referencia_sif($credencial, $referenciaEntrada);
$version = parametro_declaracion_sif($datos, 'version', 60);
$codigoSif = strtoupper(parametro_declaracion_sif($datos, 'sif', 20));
if ($codigoSif !== 'FZ') {
    responder_error('SIF_NO_RECONOCIDO', 'El SIF no está autorizado.', 422);
}
$declaracion = leer_declaracion_sif($codigoSif, $version);
$html = (string)$declaracion['html'];
responder_ok([
    'referencia' => $referencia,
    'sif' => $codigoSif,
    'version' => $version,
    'codigo_declaracion' => $declaracion['codigo'],
    'version_desde' => $declaracion['version_desde'],
    'formato' => 'text/html; charset=utf-8',
    'sha256' => hash('sha256', $html),
    'contenido_html' => $html
]);
