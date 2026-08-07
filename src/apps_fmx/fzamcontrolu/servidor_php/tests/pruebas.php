<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/privado/autenticacion.php';
require_once dirname(__DIR__) . '/privado/stock_servicio.php';
require_once dirname(__DIR__) . '/privado/fotos_servicio.php';

function comprobar(bool $condicion, string $mensaje): void
{
    if (!$condicion) {
        throw new RuntimeException('Fallo: ' . $mensaje);
    }
}

$secreto = str_repeat('a', 64);
$token = crear_token('Administrador', 3600, [], $secreto, 1_700_000_000);
$carga = verificar_token($token, $secreto, 1_700_000_100);
comprobar($carga['sub'] === 'Administrador', 'token valido');
comprobar(
    hash_password_factuzam('contraseña') === '4C882DCB24BCB1BC225391A602FECA7C',
    'MD5 heredado sobre UTF-8'
);
try {
    verificar_token($token, $secreto, 1_700_004_000);
    comprobar(false, 'token caducado rechazado');
} catch (ErrorApi $e) {
    comprobar($e->estadoHttp === 401, 'caducidad responde 401');
}
comprobar(permiso_segun_reglas([], 'Ana', 'Ventas', false),
    'permiso de menu ausente permite');
comprobar(!permiso_segun_reglas([
    ['USUARIO_GRUPO_PERM' => 'Todos', 'VALOR_PERM' => 'S'],
    ['USUARIO_GRUPO_PERM' => 'Ventas', 'VALOR_PERM' => 'S'],
    ['USUARIO_GRUPO_PERM' => 'Ana', 'VALOR_PERM' => 'N'],
], 'Ana', 'Ventas', false), 'permiso de usuario prevalece');
comprobar(permiso_segun_reglas([
    ['USUARIO_GRUPO_PERM' => 'Ana', 'VALOR_PERM' => 'N'],
], 'Ana', 'Ventas', true), 'administrador omite restricciones');

$stock = transformar_filas_stock([
    [
        'Codigo' => 'ABRIGO-PAÑO/CAMEL',
        'Almacen' => 'GENERAL',
        '38' => '2.000000',
        '40' => 1,
        'Total' => 3,
    ],
    [
        'Codigo' => 'ABRIGO-PAÑO/CAMEL',
        'Almacen' => 'TIENDA',
        '38' => 4,
        '40' => 0,
        'Total' => 4,
    ],
], 'ABRIGO-PAÑO');
comprobar($stock['stock_total'] === 7.0, 'suma de stock');
$jsonDetalle = json_encode(detalle_como_objeto($stock['detalle']), JSON_THROW_ON_ERROR);
comprobar(str_starts_with($jsonDetalle, '{'), 'detalle siempre es objeto JSON');
comprobar(str_contains($jsonDetalle, '"38"'), 'talla numerica conserva su clave');
$stockSimple = transformar_filas_stock([
    ['Codigo' => 'BOLSO-PIEL', 'Almacen' => 'GENERAL', 'Stock_Total' => '5.5'],
], 'BOLSO-PIEL');
comprobar($stockSimple['stock_total'] === 5.5, 'fallback Stock_Total');

$fotos = [
    ['CODIGO_UNIDAD_FOT' => '', 'NOMBRE_FOT_FOT' => 'general'],
    ['CODIGO_UNIDAD_FOT' => 'CAMI-POLO/AZUL', 'NOMBRE_FOT_FOT' => 'azul'],
    ['CODIGO_UNIDAD_FOT' => 'CAMI-POLO/AZUL/L', 'NOMBRE_FOT_FOT' => 'azul_l'],
];
comprobar(
    elegir_foto($fotos, 'CAMI-POLO/AZUL/L')['NOMBRE_FOT_FOT'] === 'azul_l',
    'foto exacta'
);
comprobar(
    elegir_foto($fotos, 'CAMI-POLO/AZUL/M')['NOMBRE_FOT_FOT'] === 'azul',
    'foto por prefijo'
);
$soloOtroColor = [
    ['CODIGO_UNIDAD_FOT' => 'CAMI-POLO/AZUL', 'NOMBRE_FOT_FOT' => 'azul'],
];
comprobar(elegir_foto($soloOtroColor, 'CAMI-POLO/ROJO/M') === null,
    'no usa la foto de otro color');
comprobar(nombre_foto_seguro('ABRIGO-PAÑO_001'), 'nombre Unicode valido');
comprobar(!nombre_foto_seguro('../secreto'), 'traversal rechazado');
comprobar(limite_foto_bytes(8 * 1024 * 1024) === 4 * 1024 * 1024,
    'limite absoluto de foto');
comprobar(longitud_utf8(str_repeat('Ñ', 20)) === 20, 'limites por caracteres UTF-8');

echo "Pruebas PHP: OK\n";
