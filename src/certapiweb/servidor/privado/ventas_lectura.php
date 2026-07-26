<?php
declare(strict_types=1);

require_once __DIR__ . '/autenticacion.php';

/**
 * Ayudas comunes a los endpoints de lectura de ventas.
 * Todas las consultas quedan acotadas a la referencia de la credencial,
 * de modo que una instalación nunca puede leer datos de otra.
 */

function texto_consulta(
    array $datos,
    string $nombre,
    int $maximo,
    bool $obligatorio = false
): string {
    $valor = $datos[$nombre] ?? '';
    if (!is_string($valor)) {
        responder_error(
            'PARAMETRO_INVALIDO',
            'El parámetro ' . $nombre . ' no es válido.',
            422
        );
    }
    $valor = trim($valor);
    if ($valor === '') {
        if ($obligatorio) {
            responder_error(
                'PARAMETRO_OBLIGATORIO',
                'Falta el parámetro ' . $nombre . '.',
                422
            );
        }
        return '';
    }
    if (strlen($valor) > $maximo ||
        preg_match('/[\x00-\x1F\x7F]/u', $valor) === 1) {
        responder_error(
            'PARAMETRO_INVALIDO',
            'El parámetro ' . $nombre . ' no es válido.',
            422
        );
    }
    return $valor;
}

function entero_consulta(
    array $datos,
    string $nombre,
    int $defecto,
    int $minimo,
    int $maximo
): int {
    $valor = $datos[$nombre] ?? null;
    if ($valor === null || $valor === '') {
        return $defecto;
    }
    if (!is_string($valor) || preg_match('/^\d{1,9}$/D', $valor) !== 1) {
        responder_error(
            'PARAMETRO_INVALIDO',
            'El parámetro ' . $nombre . ' debe ser un número entero.',
            422
        );
    }
    $entero = (int)$valor;
    if ($entero < $minimo) {
        $entero = $minimo;
    }
    if ($entero > $maximo) {
        $entero = $maximo;
    }
    return $entero;
}

/**
 * Las columnas de instante están en UTC, así que la fecha recibida se
 * interpreta también en UTC y no en la zona del servidor. Cuando llega
 * solo la fecha (sin hora) y se trata del extremo superior del rango,
 * se lleva al final del día para que "hasta=hoy" incluya hoy.
 */
function instante_consulta(
    array $datos,
    string $nombre,
    bool $finDeDia = false
): string {
    $valor = texto_consulta($datos, $nombre, 40);
    if ($valor === '') {
        return '';
    }
    try {
        $instante = (new DateTimeImmutable($valor, new DateTimeZone('UTC')))
            ->setTimezone(new DateTimeZone('UTC'));
    } catch (Throwable) {
        responder_error(
            'FECHA_INVALIDA',
            'El parámetro ' . $nombre . ' no es una fecha válida.',
            422
        );
    }
    $soloFecha = preg_match('/^\d{4}-\d{2}-\d{2}$/D', $valor) === 1;
    if ($finDeDia && $soloFecha) {
        $instante = $instante->setTime(23, 59, 59);
    }
    return $instante->format('Y-m-d H:i:s');
}

function tipo_documento_consulta(array $datos, string $nombre): string
{
    $valor = strtoupper(texto_consulta($datos, $nombre, 30, true));
    $permitidos = ['TICKET_PDF', 'FACTURA_PDF'];
    if (!in_array($valor, $permitidos, true)) {
        responder_error(
            'TIPO_DOCUMENTO_INVALIDO',
            'Los tipos admitidos son TICKET_PDF y FACTURA_PDF.',
            422
        );
    }
    return $valor;
}

function json_decodificado(string $texto): mixed
{
    $datos = json_decode($texto, true);
    if ($datos === null && strtolower(trim($texto)) !== 'null') {
        return [];
    }
    return $datos;
}

function buscar_venta(
    PDO $pdo,
    string $referencia,
    string $empresa,
    string $serie,
    string $numero
): array {
    $consulta = $pdo->prepare(
        'SELECT * FROM api_ventas WHERE referencia = ? ' .
        'AND codigo_empresa = ? AND serie_factura = ? ' .
        'AND numero_factura = ? LIMIT 1'
    );
    $consulta->execute([$referencia, $empresa, $serie, $numero]);
    $venta = $consulta->fetch();
    if (!$venta) {
        responder_error(
            'VENTA_NO_ENCONTRADA',
            'No hay ninguna venta con esa empresa, serie y número.',
            404
        );
    }
    return $venta;
}

function documentos_venta(PDO $pdo, int $idVenta): array
{
    $consulta = $pdo->prepare(
        'SELECT tipo_documento, nombre_archivo, tipo_mime, ' .
        'tamano_bytes, huella_sha256, id_evento, secuencia_evento, ' .
        'instante_alta, instante_modif ' .
        'FROM api_ventas_documentos WHERE id_venta = ? ' .
        'ORDER BY tipo_documento'
    );
    $consulta->execute([$idVenta]);
    $documentos = [];
    foreach ($consulta->fetchAll() as $documento) {
        $documentos[] = [
            'tipo' => (string)$documento['tipo_documento'],
            'nombre' => (string)$documento['nombre_archivo'],
            'mime' => (string)$documento['tipo_mime'],
            'tamano' => (int)$documento['tamano_bytes'],
            'sha256' => (string)$documento['huella_sha256'],
            'id_evento' => (string)$documento['id_evento'],
            'secuencia_evento' => (int)$documento['secuencia_evento'],
            'instante_alta' => (string)$documento['instante_alta'],
            'instante_modif' => (string)$documento['instante_modif']
        ];
    }
    return $documentos;
}

function lineas_venta(PDO $pdo, int $idVenta): array
{
    $consulta = $pdo->prepare(
        'SELECT datos_json FROM api_ventas_lineas ' .
        'WHERE id_venta = ? ORDER BY orden_linea'
    );
    $consulta->execute([$idVenta]);
    $lineas = [];
    foreach ($consulta->fetchAll() as $linea) {
        $lineas[] = json_decodificado((string)$linea['datos_json']);
    }
    return $lineas;
}

function resumen_venta(array $venta, int $numeroLineas): array
{
    return [
        'empresa' => (string)$venta['codigo_empresa'],
        'serie' => (string)$venta['serie_factura'],
        'numero' => (string)$venta['numero_factura'],
        'ultima_secuencia' => (int)$venta['ultima_secuencia'],
        'ultimo_tipo_evento' => (string)$venta['ultimo_tipo_evento'],
        'ultimo_id_evento' => (string)$venta['ultimo_id_evento'],
        'instante_alta' => (string)$venta['instante_alta'],
        'instante_modif' => (string)$venta['instante_modif'],
        'numero_lineas' => $numeroLineas
    ];
}
