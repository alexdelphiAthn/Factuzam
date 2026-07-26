<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/ventas_lectura.php';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
    header('Allow: GET');
    responder_error('METODO_NO_PERMITIDO', 'Método no permitido.', 405);
}
$credencial = exigir_token_api('ventas:leer');
$referencia = (string)$credencial['referencia'];
$empresa = texto_consulta($_GET, 'empresa', 20);
$serie = texto_consulta($_GET, 'serie', 20);
$numero = texto_consulta($_GET, 'numero', 20);
$tipoEvento = texto_consulta($_GET, 'tipo_evento', 30);
$desde = instante_consulta($_GET, 'desde');
$hasta = instante_consulta($_GET, 'hasta', true);
$limite = entero_consulta($_GET, 'limite', 50, 1, 200);
$desplazamiento = entero_consulta($_GET, 'desplazamiento', 0, 0, 999999);
$condiciones = ['referencia = ?'];
$parametros = [$referencia];
if ($empresa !== '') {
    $condiciones[] = 'codigo_empresa = ?';
    $parametros[] = $empresa;
}
if ($serie !== '') {
    $condiciones[] = 'serie_factura = ?';
    $parametros[] = $serie;
}
if ($numero !== '') {
    $condiciones[] = 'numero_factura = ?';
    $parametros[] = $numero;
}
if ($tipoEvento !== '') {
    $condiciones[] = 'ultimo_tipo_evento = ?';
    $parametros[] = $tipoEvento;
}
if ($desde !== '') {
    $condiciones[] = 'instante_modif >= ?';
    $parametros[] = $desde;
}
if ($hasta !== '') {
    $condiciones[] = 'instante_modif <= ?';
    $parametros[] = $hasta;
}
$filtro = implode(' AND ', $condiciones);
$pdo = db_api();
try {
    $contador = $pdo->prepare(
        'SELECT COUNT(*) AS total FROM api_ventas WHERE ' . $filtro
    );
    $contador->execute($parametros);
    $total = (int)($contador->fetch()['total'] ?? 0);
    $consulta = $pdo->prepare(
        'SELECT V.id, V.codigo_empresa, V.serie_factura, ' .
        'V.numero_factura, V.ultima_secuencia, V.ultimo_tipo_evento, ' .
        'V.ultimo_id_evento, V.instante_alta, V.instante_modif, ' .
        '(SELECT COUNT(*) FROM api_ventas_lineas L ' .
        ' WHERE L.id_venta = V.id) AS numero_lineas ' .
        'FROM api_ventas V WHERE ' . $filtro . ' ' .
        'ORDER BY V.instante_modif DESC, V.id DESC ' .
        'LIMIT ' . $limite . ' OFFSET ' . $desplazamiento
    );
    $consulta->execute($parametros);
    $filas = $consulta->fetchAll();
} catch (Throwable $error) {
    registrar_error_servidor($error);
    responder_error(
        'ERROR_CONSULTANDO_VENTAS',
        'No se pudieron consultar las ventas.',
        500
    );
}
$identificadores = [];
foreach ($filas as $fila) {
    $identificadores[] = (int)$fila['id'];
}
$documentosPorVenta = [];
if ($identificadores !== []) {
    $marcadores = implode(',', array_fill(0, count($identificadores), '?'));
    $consultaDocumentos = $pdo->prepare(
        'SELECT id_venta, tipo_documento, nombre_archivo, ' .
        'tamano_bytes, huella_sha256 FROM api_ventas_documentos ' .
        'WHERE id_venta IN (' . $marcadores . ') ORDER BY tipo_documento'
    );
    $consultaDocumentos->execute($identificadores);
    foreach ($consultaDocumentos->fetchAll() as $documento) {
        $documentosPorVenta[(int)$documento['id_venta']][] = [
            'tipo' => (string)$documento['tipo_documento'],
            'nombre' => (string)$documento['nombre_archivo'],
            'tamano' => (int)$documento['tamano_bytes'],
            'sha256' => (string)$documento['huella_sha256']
        ];
    }
}
$ventas = [];
foreach ($filas as $fila) {
    $resumen = resumen_venta($fila, (int)$fila['numero_lineas']);
    $resumen['documentos'] = $documentosPorVenta[(int)$fila['id']] ?? [];
    $ventas[] = $resumen;
}
responder_ok([
    'referencia' => $referencia,
    'total' => $total,
    'limite' => $limite,
    'desplazamiento' => $desplazamiento,
    'devueltas' => count($ventas),
    'ventas' => $ventas
]);
