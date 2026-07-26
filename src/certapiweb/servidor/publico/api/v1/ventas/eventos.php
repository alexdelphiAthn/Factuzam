<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/autenticacion.php';
require_once dirname(__DIR__, 4) . '/privado/ventas_proyeccion.php';

function texto_evento(
    array $datos,
    string $nombre,
    int $maximo
): string {
    $valor = $datos[$nombre] ?? '';
    $valor = is_string($valor) ? trim($valor) : '';
    if ($valor === '' || strlen($valor) > $maximo ||
        preg_match('/[\x00-\x1F\x7F]/u', $valor) === 1) {
        responder_error(
            'DATO_EVENTO_INVALIDO',
            'El campo ' . $nombre . ' no es válido.',
            422
        );
    }
    return $valor;
}

function json_proyeccion(mixed $valor): string
{
    $json = json_encode(
        $valor,
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
    );
    if (!is_string($json)) {
        throw new RuntimeException('No se pudo serializar la proyección.');
    }
    return $json;
}

function validar_pdf(array $venta, string $clave): ?array
{
    $documentos = $venta['documentos'] ?? [];
    if (!is_array($documentos)) {
        responder_error(
            'DOCUMENTOS_INVALIDOS',
            'El bloque documentos no es válido.',
            422
        );
    }
    $pdf = $documentos[$clave] ?? null;
    if ($pdf === null) {
        return null;
    }
    if (!is_array($pdf)) {
        responder_error('PDF_INVALIDO', 'El documento PDF no es válido.', 422);
    }
    $nombre = texto_evento($pdf, 'nombre', 255);
    if (basename($nombre) !== $nombre ||
        strtolower(pathinfo($nombre, PATHINFO_EXTENSION)) !== 'pdf') {
        responder_error(
            'NOMBRE_PDF_INVALIDO',
            'El nombre del documento PDF no es válido.',
            422
        );
    }
    $mime = texto_evento($pdf, 'mime', 100);
    if ($mime !== 'application/pdf') {
        responder_error('MIME_PDF_INVALIDO', 'El MIME del PDF no es válido.', 422);
    }
    $base64 = $pdf['contenido_base64'] ?? '';
    if (!is_string($base64) || $base64 === '') {
        responder_error('PDF_VACIO', 'No se ha recibido el documento PDF.', 422);
    }
    $contenido = base64_decode($base64, true);
    $maximo = defined('CFG_VENTAS_PDF_MAX_BYTES')
        ? (int)constant('CFG_VENTAS_PDF_MAX_BYTES')
        : 20 * 1024 * 1024;
    if (!is_string($contenido) || strlen($contenido) < 5 ||
        strlen($contenido) > $maximo ||
        substr($contenido, 0, 5) !== '%PDF-') {
        responder_error(
            'PDF_INVALIDO',
            'El documento PDF no es válido o supera el tamaño permitido.',
            422
        );
    }
    $tamano = $pdf['tamano'] ?? 0;
    if (!is_int($tamano) || $tamano !== strlen($contenido)) {
        responder_error(
            'TAMANO_PDF_INVALIDO',
            'El tamaño declarado del PDF no coincide.',
            422
        );
    }
    $huella = strtoupper(texto_evento($pdf, 'sha256', 64));
    $calculada = strtoupper(hash('sha256', $contenido));
    if (preg_match('/^[A-F0-9]{64}$/D', $huella) !== 1 ||
        !hash_equals($calculada, $huella)) {
        responder_error(
            'HUELLA_PDF_INVALIDA',
            'La huella SHA-256 del PDF no coincide.',
            422
        );
    }
    return [
        'nombre' => $nombre,
        'mime' => $mime,
        'tamano' => $tamano,
        'huella' => $huella,
        'contenido' => $contenido
    ];
}

/**
 * Fotos de artículo que acompañan a la venta. Van a nivel de venta y no de
 * línea: el emisor manda una sola copia por artículo aunque se repita en
 * varias líneas. Un PNG que no cuadre se descarta en silencio en vez de
 * tumbar la venta entera: la foto es un adorno, el importe no.
 */
function validar_fotos_articulo(array $venta): array
{
    $fotos = $venta['fotos'] ?? [];
    if (!is_array($fotos)) {
        return [];
    }
    $maximo = defined('CFG_VENTAS_FOTO_MAX_BYTES')
        ? (int)constant('CFG_VENTAS_FOTO_MAX_BYTES')
        : 4 * 1024 * 1024;
    $validas = [];
    foreach ($fotos as $foto) {
        if (!is_array($foto)) {
            continue;
        }
        $articulo = $foto['articulo'] ?? '';
        $clave = $foto['clave_unidad'] ?? '';
        $nombre = $foto['nombre'] ?? '';
        $base64 = $foto['contenido_base64'] ?? '';
        $huella = strtoupper((string)($foto['sha256'] ?? ''));
        if (!is_string($articulo) || !is_string($clave) ||
            !is_string($nombre) || !is_string($base64) ||
            $articulo === '' || $base64 === '' ||
            strlen($articulo) > 20 || strlen($clave) > 50 ||
            strlen($nombre) > 255) {
            continue;
        }
        $contenido = base64_decode($base64, true);
        if (!is_string($contenido) || strlen($contenido) < 8 ||
            strlen($contenido) > $maximo ||
            substr($contenido, 0, 8) !== "\x89PNG\r\n\x1a\n") {
            continue;
        }
        if (preg_match('/^[A-F0-9]{64}$/D', $huella) !== 1 ||
            !hash_equals(strtoupper(hash('sha256', $contenido)), $huella)) {
            continue;
        }
        $validas[$articulo . '|' . $clave] = [
            'articulo' => $articulo,
            'clave' => $clave,
            'nombre' => $nombre === '' ? $articulo . '.png' : $nombre,
            'tamano' => strlen($contenido),
            'huella' => $huella,
            'contenido' => $contenido
        ];
    }
    return array_values($validas);
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    header('Allow: POST');
    responder_error('METODO_NO_PERMITIDO', 'Método no permitido.', 405);
}
$credencial = exigir_token_api('ventas:escribir');
$cuerpo = file_get_contents('php://input');
if (!is_string($cuerpo) || $cuerpo === '') {
    responder_error('CUERPO_VACIO', 'No se ha recibido contenido.', 400);
}
$maximoCuerpo = defined('CFG_VENTAS_EVENTO_MAX_BYTES')
    ? (int)constant('CFG_VENTAS_EVENTO_MAX_BYTES')
    : 64 * 1024 * 1024;
if (strlen($cuerpo) > $maximoCuerpo) {
    responder_error('CUERPO_GRANDE', 'La petición es demasiado grande.', 413);
}
$datos = cuerpo_json_desde_texto($cuerpo);
$versionContrato = $datos['version_contrato'] ?? 0;
if (!is_int($versionContrato) || $versionContrato !== 1) {
    responder_error(
        'CONTRATO_NO_SOPORTADO',
        'La versión del contrato no está soportada.',
        422
    );
}
$idEvento = strtolower(texto_evento($datos, 'id_evento', 36));
if (preg_match(
    '/^[a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-' .
    '[89ab][a-f0-9]{3}-[a-f0-9]{12}$/D',
    $idEvento
) !== 1) {
    responder_error('ID_EVENTO_INVALIDO', 'El id del evento no es válido.', 422);
}
$secuencia = $datos['secuencia_evento'] ?? 0;
if (!is_int($secuencia) || $secuencia < 1) {
    responder_error('SECUENCIA_INVALIDA', 'La secuencia no es válida.', 422);
}
$tipoEvento = texto_evento($datos, 'tipo_evento', 30);
$tiposPermitidos = [
    'VENTA_CONFIRMADA',
    'FISCAL_ACTUALIZADO',
    'VENTA_ANULADA',
    'VENTA_REABIERTA',
    'TICKET_PDF_ACTUALIZADO',
    'FACTURA_PDF_ACTUALIZADO'
];
if (!in_array($tipoEvento, $tiposPermitidos, true)) {
    responder_error(
        'TIPO_EVENTO_INVALIDO',
        'El tipo de evento no está soportado.',
        422
    );
}
$origen = $datos['origen'] ?? null;
$documento = $datos['documento'] ?? null;
$venta = $datos['venta'] ?? null;
if (!is_array($origen) || !is_array($documento) || !is_array($venta)) {
    responder_error(
        'ESTRUCTURA_INVALIDA',
        'Faltan bloques obligatorios del evento.',
        422
    );
}
$referencia = texto_evento($origen, 'referencia', 100);
if (!hash_equals((string)$credencial['referencia'], $referencia)) {
    responder_error(
        'REFERENCIA_NO_AUTORIZADA',
        'La API no pertenece a la referencia indicada.',
        403
    );
}
$empresa = texto_evento($documento, 'empresa', 20);
$serie = texto_evento($documento, 'serie', 20);
$numero = texto_evento($documento, 'numero', 20);
$cabecera = $venta['cabecera'] ?? null;
$lineas = $venta['lineas'] ?? null;
if (!is_array($cabecera) || !is_array($lineas) || count($lineas) > 10000) {
    responder_error(
        'VENTA_INVALIDA',
        'La cabecera o las líneas de venta no son válidas.',
        422
    );
}
$bloquesArray = [
    'pagos_factura',
    'recibos',
    'efectos_venta',
    'pagos_caja',
    'operaciones_caja',
    'movimientos_almacen',
    'vales',
    'depositos',
    'relaciones'
];
foreach ($bloquesArray as $bloque) {
    if (!isset($venta[$bloque]) || !is_array($venta[$bloque])) {
        responder_error(
            'VENTA_INVALIDA',
            'El bloque ' . $bloque . ' no es válido.',
            422
        );
    }
}
$fiscal = $venta['fiscal'] ?? null;
if (!is_array($fiscal)) {
    responder_error('FISCAL_INVALIDO', 'El bloque fiscal no es válido.', 422);
}
$ticketPdf = validar_pdf($venta, 'ticket_pdf');
$facturaPdf = validar_pdf($venta, 'factura_pdf');
$fotosArticulo = validar_fotos_articulo($venta);
$generado = texto_evento($datos, 'generado_utc', 40);
try {
    $instanteGeneracion = (new DateTimeImmutable($generado))
        ->setTimezone(new DateTimeZone('UTC'))
        ->format('Y-m-d H:i:s');
} catch (Throwable) {
    responder_error(
        'FECHA_EVENTO_INVALIDA',
        'La fecha de generación no es válida.',
        422
    );
}
$huellaContenido = strtoupper(hash('sha256', $cuerpo));
$cabeceraProyectada = proyeccion_cabecera($cabecera);
$contextoLinea = [
    'referencia' => $referencia,
    'empresa' => $empresa,
    'serie' => $serie,
    'numero' => $numero,
    'fecha_venta' => $cabeceraProyectada['fecha_venta'],
    'instante_venta' => $cabeceraProyectada['instante_venta']
];
$jsonCabecera = json_proyeccion($cabecera);
$jsonPagosFactura = json_proyeccion($venta['pagos_factura']);
$jsonRecibos = json_proyeccion($venta['recibos']);
$jsonEfectosVenta = json_proyeccion($venta['efectos_venta']);
$jsonPagosCaja = json_proyeccion($venta['pagos_caja']);
$jsonOperaciones = json_proyeccion($venta['operaciones_caja']);
$jsonMovimientos = json_proyeccion($venta['movimientos_almacen']);
$jsonVales = json_proyeccion($venta['vales']);
$jsonDepositos = json_proyeccion($venta['depositos']);
$jsonRelaciones = json_proyeccion($venta['relaciones']);
$jsonFiscal = json_proyeccion($fiscal);
$pdo = db_api();
$repetido = false;
$proyectado = false;
try {
    $pdo->beginTransaction();
    $consultaEvento = $pdo->prepare(
        'SELECT id, huella_contenido FROM api_ventas_eventos ' .
        'WHERE referencia = ? AND id_evento = ? FOR UPDATE'
    );
    $consultaEvento->execute([$referencia, $idEvento]);
    $eventoPrevio = $consultaEvento->fetch();
    if ($eventoPrevio) {
        if (!hash_equals(
            (string)$eventoPrevio['huella_contenido'],
            $huellaContenido
        )) {
            $pdo->rollBack();
            responder_error(
                'ID_EVENTO_REUTILIZADO',
                'El id del evento ya existe con otro contenido.',
                409
            );
        }
        $repetido = true;
    } else {
        $insertarEvento = $pdo->prepare(
            'INSERT INTO api_ventas_eventos ' .
            '(id_credencial, referencia, id_evento, secuencia_evento, ' .
            'tipo_evento, codigo_empresa, serie_factura, numero_factura, ' .
            'version_contrato, huella_contenido, contenido_json, ' .
            'instante_generacion, instante_recepcion, id_peticion) ' .
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ' .
            'UTC_TIMESTAMP(), ?)'
        );
        $insertarEvento->execute([
            (int)$credencial['id'],
            $referencia,
            $idEvento,
            $secuencia,
            $tipoEvento,
            $empresa,
            $serie,
            $numero,
            $versionContrato,
            $huellaContenido,
            $cuerpo,
            $instanteGeneracion,
            id_peticion()
        ]);
        $consultaVenta = $pdo->prepare(
            'SELECT id, ultima_secuencia FROM api_ventas ' .
            'WHERE referencia = ? AND codigo_empresa = ? ' .
            'AND serie_factura = ? AND numero_factura = ? FOR UPDATE'
        );
        $consultaVenta->execute([$referencia, $empresa, $serie, $numero]);
        $ventaPrevia = $consultaVenta->fetch();
        if (!$ventaPrevia) {
            $insertarVenta = $pdo->prepare(
                'INSERT INTO api_ventas ' .
                '(referencia, codigo_empresa, serie_factura, numero_factura, ' .
                'ultima_secuencia, ultimo_tipo_evento, ultimo_id_evento, ' .
                'cabecera_json, pagos_factura_json, recibos_json, ' .
                'efectos_venta_json, pagos_caja_json, ' .
                'operaciones_caja_json, movimientos_almacen_json, ' .
                'vales_json, depositos_json, relaciones_json, fiscal_json, ' .
                'fecha_venta, instante_venta, tipo_factura, total_factura, ' .
                'instante_alta, instante_modif) VALUES ' .
                '(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ' .
                '?, ?, ?, ?, UTC_TIMESTAMP(), UTC_TIMESTAMP())'
            );
            $insertarVenta->execute([
                $referencia,
                $empresa,
                $serie,
                $numero,
                $secuencia,
                $tipoEvento,
                $idEvento,
                $jsonCabecera,
                $jsonPagosFactura,
                $jsonRecibos,
                $jsonEfectosVenta,
                $jsonPagosCaja,
                $jsonOperaciones,
                $jsonMovimientos,
                $jsonVales,
                $jsonDepositos,
                $jsonRelaciones,
                $jsonFiscal,
                $cabeceraProyectada['fecha_venta'],
                $cabeceraProyectada['instante_venta'],
                $cabeceraProyectada['tipo_factura'],
                $cabeceraProyectada['total_factura']
            ]);
            $idVenta = (int)$pdo->lastInsertId();
            $proyectado = true;
        } else {
            $idVenta = (int)$ventaPrevia['id'];
            if ($secuencia > (int)$ventaPrevia['ultima_secuencia']) {
                $actualizarVenta = $pdo->prepare(
                    'UPDATE api_ventas SET ultima_secuencia = ?, ' .
                    'ultimo_tipo_evento = ?, ultimo_id_evento = ?, ' .
                    'cabecera_json = ?, pagos_factura_json = ?, ' .
                    'recibos_json = ?, efectos_venta_json = ?, ' .
                    'pagos_caja_json = ?, operaciones_caja_json = ?, ' .
                    'movimientos_almacen_json = ?, vales_json = ?, ' .
                    'depositos_json = ?, relaciones_json = ?, ' .
                    'fiscal_json = ?, fecha_venta = ?, ' .
                    'instante_venta = ?, tipo_factura = ?, ' .
                    'total_factura = ?, instante_modif = UTC_TIMESTAMP() ' .
                    'WHERE id = ?'
                );
                $actualizarVenta->execute([
                    $secuencia,
                    $tipoEvento,
                    $idEvento,
                    $jsonCabecera,
                    $jsonPagosFactura,
                    $jsonRecibos,
                    $jsonEfectosVenta,
                    $jsonPagosCaja,
                    $jsonOperaciones,
                    $jsonMovimientos,
                    $jsonVales,
                    $jsonDepositos,
                    $jsonRelaciones,
                    $jsonFiscal,
                    $cabeceraProyectada['fecha_venta'],
                    $cabeceraProyectada['instante_venta'],
                    $cabeceraProyectada['tipo_factura'],
                    $cabeceraProyectada['total_factura'],
                    $idVenta
                ]);
                $proyectado = true;
            }
        }
        if ($proyectado) {
            $borrarLineas = $pdo->prepare(
                'DELETE FROM api_ventas_lineas WHERE id_venta = ?'
            );
            $borrarLineas->execute([$idVenta]);
            $columnasLinea = columnas_proyeccion_linea();
            $insertarLinea = $pdo->prepare(
                'INSERT INTO api_ventas_lineas ' .
                '(id_venta, orden_linea, datos_json, `' .
                implode('`, `', $columnasLinea) . '`) VALUES (?, ?, ?, ' .
                implode(', ', array_fill(0, count($columnasLinea), '?')) .
                ')'
            );
            foreach ($lineas as $indice => $linea) {
                if (!is_array($linea)) {
                    throw new RuntimeException('Línea de venta no válida.');
                }
                $proyeccion = proyeccion_linea($linea, $contextoLinea);
                $valoresLinea = [
                    $idVenta,
                    $indice + 1,
                    json_proyeccion($linea)
                ];
                foreach ($columnasLinea as $columnaLinea) {
                    $valoresLinea[] = $proyeccion[$columnaLinea];
                }
                $insertarLinea->execute($valoresLinea);
            }
        }
        // Las fotos no dependen de la secuencia del evento: si la huella
        // es la misma no se reescribe el blob, solo se toca la fecha.
        if ($fotosArticulo !== []) {
            $guardarFoto = $pdo->prepare(
                'INSERT INTO api_articulos_fotos ' .
                '(referencia, codigo_articulo, clave_unidad, ' .
                'nombre_archivo, tipo_mime, tamano_bytes, huella_sha256, ' .
                'contenido, instante_alta, instante_modif) VALUES ' .
                '(?, ?, ?, ?, ?, ?, ?, ?, UTC_TIMESTAMP(), UTC_TIMESTAMP()) ' .
                'ON DUPLICATE KEY UPDATE ' .
                'nombre_archivo = IF(huella_sha256 = VALUES(huella_sha256), ' .
                'nombre_archivo, VALUES(nombre_archivo)), ' .
                'tamano_bytes = IF(huella_sha256 = VALUES(huella_sha256), ' .
                'tamano_bytes, VALUES(tamano_bytes)), ' .
                'contenido = IF(huella_sha256 = VALUES(huella_sha256), ' .
                'contenido, VALUES(contenido)), ' .
                'instante_modif = UTC_TIMESTAMP(), ' .
                'huella_sha256 = VALUES(huella_sha256)'
            );
            foreach ($fotosArticulo as $foto) {
                $guardarFoto->execute([
                    $referencia,
                    $foto['articulo'],
                    $foto['clave'],
                    $foto['nombre'],
                    'image/png',
                    $foto['tamano'],
                    $foto['huella'],
                    $foto['contenido']
                ]);
            }
        }
        $documentosPdf = [
            'TICKET_PDF' => $ticketPdf,
            'FACTURA_PDF' => $facturaPdf
        ];
        foreach ($documentosPdf as $tipoDocumento => $documentoPdf) {
            if ($documentoPdf !== null) {
                $guardarPdf = $pdo->prepare(
                    'INSERT INTO api_ventas_documentos ' .
                    '(id_venta, tipo_documento, nombre_archivo, tipo_mime, ' .
                    'tamano_bytes, huella_sha256, contenido, id_evento, ' .
                    'secuencia_evento, instante_alta, instante_modif) ' .
                    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ' .
                    'UTC_TIMESTAMP(), UTC_TIMESTAMP()) ' .
                    'ON DUPLICATE KEY UPDATE ' .
                    'nombre_archivo = IF(VALUES(secuencia_evento) >= ' .
                    'secuencia_evento, VALUES(nombre_archivo), ' .
                    'nombre_archivo), ' .
                    'tipo_mime = IF(VALUES(secuencia_evento) >= ' .
                    'secuencia_evento, VALUES(tipo_mime), tipo_mime), ' .
                    'tamano_bytes = IF(VALUES(secuencia_evento) >= ' .
                    'secuencia_evento, VALUES(tamano_bytes), tamano_bytes), ' .
                    'huella_sha256 = IF(VALUES(secuencia_evento) >= ' .
                    'secuencia_evento, VALUES(huella_sha256), ' .
                    'huella_sha256), ' .
                    'contenido = IF(VALUES(secuencia_evento) >= ' .
                    'secuencia_evento, VALUES(contenido), contenido), ' .
                    'id_evento = IF(VALUES(secuencia_evento) >= ' .
                    'secuencia_evento, VALUES(id_evento), id_evento), ' .
                    'instante_modif = IF(VALUES(secuencia_evento) >= ' .
                    'secuencia_evento, UTC_TIMESTAMP(), instante_modif), ' .
                    'secuencia_evento = GREATEST(' .
                    'secuencia_evento, VALUES(secuencia_evento))'
                );
                $guardarPdf->execute([
                    $idVenta,
                    $tipoDocumento,
                    $documentoPdf['nombre'],
                    $documentoPdf['mime'],
                    $documentoPdf['tamano'],
                    $documentoPdf['huella'],
                    $documentoPdf['contenido'],
                    $idEvento,
                    $secuencia
                ]);
            }
        }
    }
    $pdo->commit();
} catch (Throwable $error) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    registrar_error_servidor($error);
    responder_error(
        'ERROR_GUARDANDO_VENTA',
        'No se pudo almacenar el evento de venta.',
        500
    );
}
responder_ok(
    [
        'id_evento' => $idEvento,
        'secuencia_evento' => $secuencia,
        'repetido' => $repetido,
        'proyectado' => $proyectado
    ],
    $repetido ? 200 : 201
);
