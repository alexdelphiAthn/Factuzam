<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/ventas_lectura.php';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
    header('Allow: GET');
    responder_error('METODO_NO_PERMITIDO', 'Método no permitido.', 405);
}
$credencial = exigir_token_api('ventas:leer');
$referencia = (string)$credencial['referencia'];
$empresa = texto_consulta($_GET, 'empresa', 20, true);
$serie = texto_consulta($_GET, 'serie', 20, true);
$numero = texto_consulta($_GET, 'numero', 20, true);
$incluirLineas = entero_consulta($_GET, 'incluir_lineas', 1, 0, 1);
$maximoEventos = entero_consulta($_GET, 'maximo_eventos', 20, 0, 100);
$pdo = db_api();
try {
    $venta = buscar_venta($pdo, $referencia, $empresa, $serie, $numero);
    $idVenta = (int)$venta['id'];
    $lineas = [];
    if ($incluirLineas === 1) {
        $lineas = lineas_venta($pdo, $idVenta);
    }
    $eventos = [];
    if ($maximoEventos > 0) {
        $consultaEventos = $pdo->prepare(
            'SELECT id_evento, secuencia_evento, tipo_evento, ' .
            'version_contrato, huella_contenido, instante_generacion, ' .
            'instante_recepcion, id_peticion, ' .
            'CHAR_LENGTH(contenido_json) AS tamano_json ' .
            'FROM api_ventas_eventos WHERE referencia = ? ' .
            'AND codigo_empresa = ? AND serie_factura = ? ' .
            'AND numero_factura = ? ' .
            'ORDER BY secuencia_evento DESC, id DESC LIMIT ' .
            $maximoEventos
        );
        $consultaEventos->execute([$referencia, $empresa, $serie, $numero]);
        foreach ($consultaEventos->fetchAll() as $evento) {
            $eventos[] = [
                'id_evento' => (string)$evento['id_evento'],
                'secuencia_evento' => (int)$evento['secuencia_evento'],
                'tipo_evento' => (string)$evento['tipo_evento'],
                'version_contrato' => (int)$evento['version_contrato'],
                'huella_contenido' => (string)$evento['huella_contenido'],
                'instante_generacion' =>
                    (string)($evento['instante_generacion'] ?? ''),
                'instante_recepcion' => (string)$evento['instante_recepcion'],
                'id_peticion' => (string)$evento['id_peticion'],
                'tamano_json' => (int)$evento['tamano_json']
            ];
        }
    }
    $documentos = documentos_venta($pdo, $idVenta);
} catch (Throwable $error) {
    registrar_error_servidor($error);
    responder_error(
        'ERROR_CONSULTANDO_VENTA',
        'No se pudo consultar la venta.',
        500
    );
}
$resumen = resumen_venta($venta, count($lineas));
if ($incluirLineas === 0) {
    $resumen['numero_lineas'] = null;
}
responder_ok([
    'referencia' => $referencia,
    'venta' => $resumen,
    'cabecera' => json_decodificado((string)$venta['cabecera_json']),
    'lineas' => $lineas,
    'pagos_factura' =>
        json_decodificado((string)$venta['pagos_factura_json']),
    'recibos' => json_decodificado((string)$venta['recibos_json']),
    'efectos_venta' =>
        json_decodificado((string)$venta['efectos_venta_json']),
    'pagos_caja' => json_decodificado((string)$venta['pagos_caja_json']),
    'operaciones_caja' =>
        json_decodificado((string)$venta['operaciones_caja_json']),
    'movimientos_almacen' =>
        json_decodificado((string)$venta['movimientos_almacen_json']),
    'vales' => json_decodificado((string)$venta['vales_json']),
    'depositos' => json_decodificado((string)$venta['depositos_json']),
    'relaciones' => json_decodificado((string)$venta['relaciones_json']),
    'fiscal' => json_decodificado((string)$venta['fiscal_json']),
    'documentos' => $documentos,
    'eventos' => $eventos
]);
