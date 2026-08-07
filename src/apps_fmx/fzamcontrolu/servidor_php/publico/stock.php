<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/privado/comun.php';
require_once dirname(__DIR__) . '/privado/autenticacion.php';
require_once dirname(__DIR__) . '/privado/stock_servicio.php';

ejecutar_endpoint(function (): void {
    exigir_metodo('GET');
    $identidad = exigir_usuario_autenticado();
    exigir_permiso_consulta_stock($identidad);
    $codigo = texto_sin_controles($_GET['articulo'] ?? '', 50);
    if ($codigo === '') {
        abortar_api(400, 'CODIGO_INVALIDO', 'Indica un articulo, SKU o codigo de barras.');
    }

    $pdo = conexion_bd();
    $identidad = resolver_articulo($pdo, $codigo);
    if ($identidad === null) {
        abortar_api(404, 'ARTICULO_NO_ENCONTRADO', 'No existe el articulo indicado.');
    }
    $filas = consultar_filas_stock($pdo, $identidad['consulta_stock']);
    $stock = transformar_filas_stock($filas, $identidad['articulo']);

    $parametrosFoto = ['articulo' => $identidad['articulo']];
    if ($identidad['unidad'] !== '') {
        $parametrosFoto['unidad'] = $identidad['unidad'];
    }
    responder_ok([
        'articulo' => $identidad['articulo'],
        'descripcion' => $identidad['descripcion'],
        'stock_total' => $stock['stock_total'],
        'foto_300_url' => 'foto.php?' . http_build_query(
            $parametrosFoto,
            '',
            '&',
            PHP_QUERY_RFC3986
        ),
        'detalle' => detalle_como_objeto($stock['detalle']),
    ]);
});
