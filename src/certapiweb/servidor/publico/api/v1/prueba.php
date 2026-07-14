<?php
declare(strict_types=1);

require dirname(__DIR__, 3) . '/privado/autenticacion.php';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
    header('Allow: GET');
    responder_error('METODO_NO_PERMITIDO', 'Método no permitido.', 405);
}

$credencial = exigir_token_api('prueba:leer');
responder_ok([
    'autenticada' => true,
    'id_api' => (int)$credencial['id'],
    'referencia' => $credencial['referencia'],
    'ambitos' => $credencial['ambitos_decodificados']
]);
