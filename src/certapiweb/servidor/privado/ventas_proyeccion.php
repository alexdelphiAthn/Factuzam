<?php
declare(strict_types=1);

/**
 * Proyección de la venta recibida a columnas consultables.
 *
 * El evento llega con las filas de Factuzam tal cual, con sus nombres de
 * columna originales. Aquí se traducen a los campos que consulta el listado
 * móvil. Se guarda además el JSON íntegro, así que esto es una vista de
 * conveniencia: si algún día hace falta otro campo, se añade la columna y se
 * rellena desde el JSON sin haber perdido nada.
 */

function texto_proyectado(mixed $valor, int $maximo): ?string
{
    if ($valor === null || is_array($valor)) {
        return null;
    }
    if (is_bool($valor)) {
        $valor = $valor ? 'S' : 'N';
    }
    $texto = trim((string)$valor);
    if ($texto === '') {
        return '';
    }
    return mb_substr($texto, 0, $maximo);
}

function numero_proyectado(mixed $valor): float
{
    if (is_int($valor) || is_float($valor)) {
        return (float)$valor;
    }
    if (is_string($valor) && is_numeric(trim($valor))) {
        return (float)trim($valor);
    }
    return 0.0;
}

/** Las fechas viajan como 'aaaa-mm-dd'. Cualquier otra cosa se descarta. */
function fecha_proyectada(mixed $valor): ?string
{
    $texto = texto_proyectado($valor, 10);
    if ($texto === null || $texto === '' ||
        preg_match('/^\d{4}-\d{2}-\d{2}$/D', $texto) !== 1) {
        return null;
    }
    return $texto;
}

/** Los datetime viajan en ISO 8601 UTC: 2026-07-25T18:00:00.000Z */
function instante_proyectado(mixed $valor): ?string
{
    $texto = texto_proyectado($valor, 40);
    if ($texto === null || $texto === '') {
        return null;
    }
    try {
        return (new DateTimeImmutable($texto))
            ->setTimezone(new DateTimeZone('UTC'))
            ->format('Y-m-d H:i:s');
    } catch (Throwable) {
        return null;
    }
}

/** El SKU es ARTICULO/COLOR/TALLA; sin los tres tramos no hay color. */
function color_desde_sku(?string $sku): string
{
    if ($sku === null || $sku === '') {
        return '';
    }
    $tramos = explode('/', $sku);
    if (count($tramos) < 3) {
        return '';
    }
    return mb_substr($tramos[1], 0, 50);
}

function proyeccion_cabecera(array $cabecera): array
{
    $instante = instante_proyectado($cabecera['INSTANTECONSO_FAC'] ?? null);
    if ($instante === null) {
        $instante = instante_proyectado($cabecera['INSTANTE_ALTA'] ?? null);
    }
    return [
        'fecha_venta' => fecha_proyectada($cabecera['FECHA_FAC'] ?? null),
        'instante_venta' => $instante,
        'tipo_factura' => texto_proyectado($cabecera['TIPO_FAC'] ?? null, 20),
        'total_factura' =>
            numero_proyectado($cabecera['TOTAL_LIQUIDO_FAC'] ?? null)
    ];
}

/**
 * $contexto trae referencia, empresa, serie, numero y la proyección de la
 * cabecera, que se copian a cada línea para que el listado del día se
 * resuelva con un solo índice sin tocar api_ventas.
 */
function proyeccion_linea(array $linea, array $contexto): array
{
    $sku = texto_proyectado($linea['CODIGO_UNIDAD_FACLIN'] ?? null, 50);
    $cantidad = numero_proyectado($linea['CANTIDAD_FACLIN'] ?? null);
    $coste = numero_proyectado($linea['PRECIO_ULT_COMPRA_FACLIN'] ?? null);
    $pvp = numero_proyectado($linea['PRECIO_SALIDA_FACLIN'] ?? null);
    $totalLinea = numero_proyectado($linea['TOTAL_FACLIN'] ?? null);
    $totalSiva = numero_proyectado($linea['TOTAL_FAC_SIVA_FACLIN'] ?? null);
    // Descuento = PVP de tarifa menos lo realmente cobrado. Lo cobrado se
    // saca del total de la línea y NO de PRECIO_DTO_FACLIN, porque ese campo
    // no significa lo mismo en todos los caminos del programa: unas veces
    // guarda el precio ya rebajado y otras el importe del descuento.
    // La comparación se hace sobre la misma base que la tarifa: con IVA si
    // ESIMP_INCL_TARIFA es 'S', y sin IVA si es 'N'.
    $tarifaSinIva = strtoupper(trim(
        (string)($linea['ESIMP_INCL_TARIFA_FACLIN'] ?? 'S'))) === 'N';
    $cobrado = $tarifaSinIva ? $totalSiva : $totalLinea;
    $importeDto = ($pvp * $cantidad) - $cobrado;
    if ($importeDto < 0) {
        $importeDto = 0.0;
    }
    $precioCobrado = 0.0;
    if ($cantidad != 0.0) {
        $precioCobrado = $cobrado / $cantidad;
    }
    return [
        'referencia' => $contexto['referencia'],
        'fecha_venta' => $contexto['fecha_venta'],
        'instante_venta' => $contexto['instante_venta'],
        'codigo_empresa' => $contexto['empresa'],
        'serie_factura' => $contexto['serie'],
        'numero_factura' => $contexto['numero'],
        'linea' => texto_proyectado($linea['LINEA_FACLIN'] ?? null, 4),
        'codigo_articulo' =>
            texto_proyectado($linea['CODIGO_ART_FACLIN'] ?? null, 20),
        'sku' => $sku,
        'color' => color_desde_sku($sku),
        'descripcion' =>
            texto_proyectado($linea['DESCRIPCION_ARTICULO_FACLIN'] ?? null, 200),
        'descripcion_variacion' =>
            texto_proyectado($linea['DESCRIPCION_VARIACION_FACLIN'] ?? null, 200),
        'codigo_familia' =>
            texto_proyectado($linea['CODIGO_FAM_FACLIN'] ?? null, 20),
        'nombre_familia' =>
            texto_proyectado($linea['NOMBRE_FAM_FACLIN'] ?? null, 200),
        // Siempre cadena, nunca NULL: así el filtro por temporada y el
        // índice se comportan igual en filas viejas y nuevas.
        'temporada' =>
            texto_proyectado($linea['TEMPORADA_CALC'] ?? null, 100) ?? '',
        'codigo_proveedor' =>
            texto_proyectado($linea['CODIGO_PRV_FACLIN'] ?? null, 20),
        'nombre_proveedor' => texto_proyectado(
            $linea['RAZON_SOCIAL_PROVEEDOR_FACLIN'] ?? null, 200),
        'cantidad' => $cantidad,
        'precio_coste' => $coste,
        'pvp' => $pvp,
        'porcentaje_descuento' =>
            numero_proyectado($linea['PORCENTAJE_DTO_FACLIN'] ?? null),
        'precio_con_descuento' => $precioCobrado,
        'importe_descuento' => $importeDto,
        'precio_venta' => numero_proyectado(
            $linea['PRECIO_VENTA_CIVA_ARTICULO_FACLIN'] ?? null),
        'total_linea' => numero_proyectado($linea['TOTAL_FACLIN'] ?? null),
        'total_linea_siva' =>
            numero_proyectado($linea['TOTAL_FAC_SIVA_FACLIN'] ?? null),
        'total_coste' => $coste * $cantidad
    ];
}

/** Columnas proyectadas de api_ventas_lineas, en orden fijo para el INSERT. */
function columnas_proyeccion_linea(): array
{
    return [
        'referencia', 'fecha_venta', 'instante_venta', 'codigo_empresa',
        'serie_factura', 'numero_factura', 'linea', 'codigo_articulo',
        'sku', 'color', 'descripcion', 'descripcion_variacion',
        'codigo_familia', 'nombre_familia', 'temporada',
        'codigo_proveedor', 'nombre_proveedor', 'cantidad',
        'precio_coste', 'pvp', 'porcentaje_descuento',
        'precio_con_descuento', 'importe_descuento', 'precio_venta',
        'total_linea', 'total_linea_siva', 'total_coste'
    ];
}
