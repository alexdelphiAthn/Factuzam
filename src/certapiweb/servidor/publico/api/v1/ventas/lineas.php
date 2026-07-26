<?php
declare(strict_types=1);

require dirname(__DIR__, 4) . '/privado/ventas_lectura.php';

/**
 * Listado plano de líneas de venta con totales por día.
 *
 * Es lo que consume la app de móvil. A diferencia de listar.php / detalle.php,
 * que devuelven documentos completos, aquí la unidad es la línea: una fila por
 * artículo vendido, ya con familia, temporada, proveedor, coste y precios.
 *
 * Nota sobre el margen: el coste no lleva IVA, así que restarlo de la venta
 * con IVA daría un margen inflado. El margen se calcula siempre contra la
 * base imponible (total_venta_siva - total_coste) y se devuelven las dos
 * cifras de venta para que la app pueda enseñar la que toque.
 */

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
    header('Allow: GET');
    responder_error('METODO_NO_PERMITIDO', 'Método no permitido.', 405);
}
$credencial = exigir_token_api('ventas:leer');
$referencia = (string)$credencial['referencia'];
$fecha = instante_consulta($_GET, 'fecha');
if ($fecha !== '') {
    $desde = substr($fecha, 0, 10);
    $hasta = $desde;
} else {
    $desde = substr(instante_consulta($_GET, 'desde'), 0, 10);
    $hasta = substr(instante_consulta($_GET, 'hasta'), 0, 10);
}
if ($desde === '' && $hasta === '') {
    responder_error(
        'FALTA_FECHA',
        'Indique fecha, o bien desde y hasta.',
        422
    );
}
if ($desde === '') {
    $desde = $hasta;
}
if ($hasta === '') {
    $hasta = $desde;
}
if ($desde > $hasta) {
    responder_error(
        'RANGO_INVALIDO',
        'La fecha inicial es posterior a la final.',
        422
    );
}
$empresa = texto_consulta($_GET, 'empresa', 20);
$familia = texto_consulta($_GET, 'familia', 20);
$proveedor = texto_consulta($_GET, 'proveedor', 20);
$temporada = texto_consulta($_GET, 'temporada', 100);
$articulo = texto_consulta($_GET, 'articulo', 20);
$texto = texto_consulta($_GET, 'texto', 100);
$incluirAnuladas = entero_consulta($_GET, 'incluir_anuladas', 0, 0, 1);
$limite = entero_consulta($_GET, 'limite', 200, 1, 1000);
$desplazamiento = entero_consulta($_GET, 'desplazamiento', 0, 0, 999999);
$condiciones = ['L.referencia = ?', 'L.fecha_venta BETWEEN ? AND ?'];
$parametros = [$referencia, $desde, $hasta];
if ($empresa !== '') {
    $condiciones[] = 'L.codigo_empresa = ?';
    $parametros[] = $empresa;
}
if ($familia !== '') {
    $condiciones[] = 'L.codigo_familia = ?';
    $parametros[] = $familia;
}
if ($proveedor !== '') {
    $condiciones[] = 'L.codigo_proveedor = ?';
    $parametros[] = $proveedor;
}
if ($temporada !== '') {
    $condiciones[] = 'L.temporada = ?';
    $parametros[] = $temporada;
}
if ($articulo !== '') {
    $condiciones[] = 'L.codigo_articulo = ?';
    $parametros[] = $articulo;
}
if ($texto !== '') {
    $condiciones[] = '(L.descripcion LIKE ? OR L.sku LIKE ? ' .
                     'OR L.codigo_articulo LIKE ?)';
    $comodin = '%' . str_replace(['\\', '%', '_'],
                                 ['\\\\', '\%', '\_'], $texto) . '%';
    $parametros[] = $comodin;
    $parametros[] = $comodin;
    $parametros[] = $comodin;
}
if ($incluirAnuladas === 0) {
    $condiciones[] = 'V.ultimo_tipo_evento <> ?';
    $parametros[] = 'VENTA_ANULADA';
}
$filtro = implode(' AND ', $condiciones);
$origen = 'api_ventas_lineas L ' .
          'INNER JOIN api_ventas V ON V.id = L.id_venta';
$pdo = db_api();
try {
    $contador = $pdo->prepare(
        'SELECT COUNT(*) AS total FROM ' . $origen . ' WHERE ' . $filtro
    );
    $contador->execute($parametros);
    $totalLineas = (int)($contador->fetch()['total'] ?? 0);
    $consulta = $pdo->prepare(
        'SELECT L.fecha_venta, L.instante_venta, L.codigo_empresa, ' .
        'L.serie_factura, L.numero_factura, L.linea, L.codigo_articulo, ' .
        'L.sku, L.color, L.descripcion, L.descripcion_variacion, ' .
        'L.codigo_familia, L.nombre_familia, L.temporada, ' .
        'L.codigo_proveedor, L.nombre_proveedor, L.cantidad, ' .
        'L.precio_coste, L.pvp, L.porcentaje_descuento, ' .
        'L.precio_con_descuento, L.importe_descuento, L.precio_venta, ' .
        'L.total_linea, L.total_linea_siva, L.total_coste, ' .
        'V.ultimo_tipo_evento ' .
        'FROM ' . $origen . ' WHERE ' . $filtro . ' ' .
        'ORDER BY L.fecha_venta DESC, L.instante_venta DESC, ' .
        'L.serie_factura, L.numero_factura, L.linea ' .
        'LIMIT ' . $limite . ' OFFSET ' . $desplazamiento
    );
    $consulta->execute($parametros);
    $filas = $consulta->fetchAll();
    // Los totales se calculan sobre TODO el filtro, no sobre la página.
    $sumas =
        'SUM(L.cantidad) AS unidades, ' .
        'SUM(L.total_linea) AS total_venta, ' .
        'SUM(L.total_linea_siva) AS total_venta_siva, ' .
        'SUM(L.total_coste) AS total_coste, ' .
        'SUM(L.importe_descuento) AS total_descuento, ' .
        'COUNT(*) AS lineas';
    $porDia = $pdo->prepare(
        'SELECT L.fecha_venta, ' . $sumas . ' FROM ' . $origen .
        ' WHERE ' . $filtro . ' GROUP BY L.fecha_venta ' .
        'ORDER BY L.fecha_venta DESC'
    );
    $porDia->execute($parametros);
    $filasDia = $porDia->fetchAll();
    $global = $pdo->prepare(
        'SELECT ' . $sumas . ' FROM ' . $origen . ' WHERE ' . $filtro
    );
    $global->execute($parametros);
    $filaGlobal = $global->fetch();
} catch (Throwable $error) {
    registrar_error_servidor($error);
    responder_error(
        'ERROR_CONSULTANDO_LINEAS',
        'No se pudieron consultar las líneas de venta.',
        500
    );
}

function totales_bloque(array $fila): array
{
    $venta = (float)($fila['total_venta'] ?? 0);
    $ventaSiva = (float)($fila['total_venta_siva'] ?? 0);
    $coste = (float)($fila['total_coste'] ?? 0);
    $margen = $ventaSiva - $coste;
    $porcentaje = 0.0;
    if ($ventaSiva != 0.0) {
        $porcentaje = round($margen / $ventaSiva * 100, 2);
    }
    return [
        'lineas' => (int)($fila['lineas'] ?? 0),
        'unidades' => round((float)($fila['unidades'] ?? 0), 3),
        'total_venta' => round($venta, 2),
        'total_venta_siva' => round($ventaSiva, 2),
        'total_coste' => round($coste, 2),
        'total_margen' => round($margen, 2),
        'porcentaje_margen' => $porcentaje,
        'total_descuento' => round(
            (float)($fila['total_descuento'] ?? 0), 2)
    ];
}

$lineas = [];
foreach ($filas as $fila) {
    $codigoArticulo = (string)($fila['codigo_articulo'] ?? '');
    $color = (string)($fila['color'] ?? '');
    $instante = (string)($fila['instante_venta'] ?? '');
    // La foto sale de api_articulos_fotos, que se rellena con el propio
    // evento de venta: no depende del subsistema fotos_nube ni del ámbito
    // fotos:leer. Se manda el SKU completo para que el servidor aplique el
    // mismo fallback que Factuzam (SKU -> color -> artículo).
    $rutaFoto = '';
    if ($codigoArticulo !== '') {
        $rutaFoto = 'ventas/foto.php?' . http_build_query([
            'articulo' => $codigoArticulo,
            'sku' => (string)($fila['sku'] ?? '')
        ]);
    }
    $lineas[] = [
        'fecha' => (string)($fila['fecha_venta'] ?? ''),
        'hora' => $instante === '' ? '' : substr($instante, 11, 5),
        'instante_venta' => $instante,
        'empresa' => (string)($fila['codigo_empresa'] ?? ''),
        'serie' => (string)($fila['serie_factura'] ?? ''),
        'numero' => (string)($fila['numero_factura'] ?? ''),
        'linea' => (string)($fila['linea'] ?? ''),
        'articulo' => $codigoArticulo,
        'sku' => (string)($fila['sku'] ?? ''),
        'color' => $color,
        'descripcion' => (string)($fila['descripcion'] ?? ''),
        'variacion' => (string)($fila['descripcion_variacion'] ?? ''),
        'codigo_familia' => (string)($fila['codigo_familia'] ?? ''),
        'familia' => (string)($fila['nombre_familia'] ?? ''),
        'temporada' => (string)($fila['temporada'] ?? ''),
        'codigo_proveedor' => (string)($fila['codigo_proveedor'] ?? ''),
        'proveedor' => (string)($fila['nombre_proveedor'] ?? ''),
        'cantidad' => round((float)($fila['cantidad'] ?? 0), 3),
        'precio_coste' => round((float)($fila['precio_coste'] ?? 0), 2),
        'pvp' => round((float)($fila['pvp'] ?? 0), 2),
        'porcentaje_descuento' =>
            round((float)($fila['porcentaje_descuento'] ?? 0), 2),
        'precio_con_descuento' =>
            round((float)($fila['precio_con_descuento'] ?? 0), 2),
        'importe_descuento' =>
            round((float)($fila['importe_descuento'] ?? 0), 2),
        'precio_venta' => round((float)($fila['precio_venta'] ?? 0), 2),
        'total_linea' => round((float)($fila['total_linea'] ?? 0), 2),
        'total_linea_siva' =>
            round((float)($fila['total_linea_siva'] ?? 0), 2),
        'total_coste' => round((float)($fila['total_coste'] ?? 0), 2),
        'anulada' =>
            ($fila['ultimo_tipo_evento'] ?? '') === 'VENTA_ANULADA',
        'foto_ruta' => $rutaFoto
    ];
}
$totalesDia = [];
foreach ($filasDia as $filaDia) {
    $bloque = totales_bloque($filaDia);
    $bloque['fecha'] = (string)($filaDia['fecha_venta'] ?? '');
    $totalesDia[] = $bloque;
}
responder_ok([
    'referencia' => $referencia,
    'desde' => $desde,
    'hasta' => $hasta,
    'limite' => $limite,
    'desplazamiento' => $desplazamiento,
    'total_lineas' => $totalLineas,
    'devueltas' => count($lineas),
    'lineas' => $lineas,
    'totales_dia' => $totalesDia,
    'totales' => totales_bloque(
        is_array($filaGlobal) ? $filaGlobal : [])
]);
