<?php

declare(strict_types=1);

require_once __DIR__ . DIRECTORY_SEPARATOR . 'comun.php';

function resolver_articulo(PDO $pdo, string $codigo): ?array
{
    $consulta = $pdo->prepare(
        "SELECT CODIGO_ART_ART AS articulo,
                DESCRIPCION_ART AS descripcion
           FROM fza_articulos
          WHERE CODIGO_ART_ART = :codigo
            AND ESACTIVO_ART = 'S'
          LIMIT 1"
    );
    $consulta->execute(['codigo' => $codigo]);
    $fila = $consulta->fetch();
    if (is_array($fila)) {
        return [
            'articulo' => (string) $fila['articulo'],
            'descripcion' => (string) $fila['descripcion'],
            'unidad' => '',
            'consulta_stock' => (string) $fila['articulo'],
        ];
    }

    $consulta = $pdo->prepare(
        "SELECT s.CODIGO_ART_SKU AS articulo,
                a.DESCRIPCION_ART AS descripcion,
                s.CODIGO_UNIDAD_SKU AS unidad
           FROM fza_articulos_skus s
           JOIN fza_articulos a
             ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU
          WHERE s.CODIGO_UNIDAD_SKU = :codigo
            AND COALESCE(s.ESACTIVO_SKU, 'S') = 'S'
            AND a.ESACTIVO_ART = 'S'
          LIMIT 1"
    );
    $consulta->execute(['codigo' => $codigo]);
    $fila = $consulta->fetch();
    if (is_array($fila)) {
        return [
            'articulo' => (string) $fila['articulo'],
            'descripcion' => (string) $fila['descripcion'],
            'unidad' => (string) $fila['unidad'],
            'consulta_stock' => (string) $fila['unidad'],
        ];
    }

    $consulta = $pdo->prepare(
        "SELECT s.CODIGO_ART_SKU AS articulo,
                a.DESCRIPCION_ART AS descripcion,
                s.CODIGO_UNIDAD_SKU AS unidad
           FROM fza_codigos_barras cb
           JOIN fza_articulos_skus s
             ON s.CODIGO_UNIDAD_SKU = cb.CODIGO_UNIDAD_CB
           JOIN fza_articulos a
             ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU
          WHERE cb.CODIGO_BARRAS_CB = :codigo
            AND COALESCE(s.ESACTIVO_SKU, 'S') = 'S'
            AND a.ESACTIVO_ART = 'S'
          ORDER BY CASE WHEN cb.ESPRINCIPAL_CB = 'S' THEN 0 ELSE 1 END,
                   cb.ID_CB
          LIMIT 1"
    );
    $consulta->execute(['codigo' => $codigo]);
    $fila = $consulta->fetch();
    if (!is_array($fila)) {
        return null;
    }
    return [
        'articulo' => (string) $fila['articulo'],
        'descripcion' => (string) $fila['descripcion'],
        'unidad' => (string) $fila['unidad'],
        'consulta_stock' => (string) $fila['unidad'],
    ];
}

function consultar_filas_stock(PDO $pdo, string $codigo): array
{
    // El procedimiento heredado interpola este maestro en SQL dinamico sin
    // QUOTE(). Solo recibe codigos ya resueltos en BD; aun asi, rechazamos el
    // caracter que podria cerrar su literal y evitamos inyeccion de segundo orden.
    if (str_contains($codigo, "'")) {
        abortar_api(
            422,
            'CODIGO_NO_COMPATIBLE',
            'El codigo contiene un caracter no admitido por la consulta de stock.'
        );
    }
    $consulta = $pdo->prepare('CALL PRC_GET_CAJA_STOCK_PIVOTADO(:codigo)');
    $consulta->execute(['codigo' => $codigo]);
    $filas = $consulta->fetchAll();
    do {
        // Consumir todos los result sets para que PDO permita otra consulta.
    } while ($consulta->nextRowset());
    $consulta->closeCursor();
    return is_array($filas) ? $filas : [];
}

function numero_stock(mixed $valor): float
{
    return is_numeric($valor) ? (float) $valor : 0.0;
}

function transformar_filas_stock(array $filas, string $articulo): array
{
    $detalle = [];
    $total = 0.0;
    foreach ($filas as $fila) {
        if (!is_array($fila)) {
            continue;
        }
        $codigoFila = (string) ($fila['Codigo'] ?? $articulo);
        $almacen = trim((string) ($fila['Almacen'] ?? ''));
        if ($almacen === '') {
            $almacen = 'SIN ALMACEN';
        }
        $color = 'GENERAL';
        $prefijo = $articulo . '/';
        if (str_starts_with($codigoFila, $prefijo)) {
            $color = substr($codigoFila, strlen($prefijo));
            if ($color === '') {
                $color = 'GENERAL';
            }
        }

        if (array_key_exists('Stock_Total', $fila)) {
            $unidades = numero_stock($fila['Stock_Total']);
            $detalle[$color]['UNICA'][$almacen] =
                ($detalle[$color]['UNICA'][$almacen] ?? 0.0) + $unidades;
            $total += $unidades;
            continue;
        }

        foreach ($fila as $talla => $valor) {
            if (in_array($talla, ['Codigo', 'Almacen', 'Total'], true)) {
                continue;
            }
            if (!is_numeric($valor)) {
                continue;
            }
            $nombreTalla = trim((string) $talla);
            if ($nombreTalla === '') {
                $nombreTalla = 'UNICA';
            }
            $unidades = (float) $valor;
            $detalle[$color][$nombreTalla][$almacen] =
                ($detalle[$color][$nombreTalla][$almacen] ?? 0.0) + $unidades;
            $total += $unidades;
        }
    }
    return ['detalle' => $detalle, 'stock_total' => $total];
}

function detalle_como_objeto(array $detalle): stdClass
{
    $colores = new stdClass();
    foreach ($detalle as $color => $tallas) {
        $objTallas = new stdClass();
        foreach ($tallas as $talla => $almacenes) {
            $objAlmacenes = new stdClass();
            foreach ($almacenes as $almacen => $unidades) {
                $objAlmacenes->{(string) $almacen} = (float) $unidades;
            }
            $objTallas->{(string) $talla} = $objAlmacenes;
        }
        $colores->{(string) $color} = $objTallas;
    }
    return $colores;
}
