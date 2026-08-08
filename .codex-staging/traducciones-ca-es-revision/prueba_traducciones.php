<?php
declare(strict_types=1);

require dirname(__DIR__) . '/privado/traducciones.php';

$esperados = [
    'en-GB' => ['version' => 1, 'archivos' => 2],
    'ca-ES' => ['version' => 2, 'archivos' => 3],
    'zh-CN' => ['version' => 4, 'archivos' => 4]
];
$valido = in_array(
    'descargar:traducciones',
    CFG_AMBITOS_PERMITIDOS,
    true
);
foreach ($esperados as $idiomaEsperado => $esperado) {
    $idioma = normalizar_idioma_traduccion(strtolower($idiomaEsperado));
    $traduccion = obtener_traduccion($idioma);
    $archivos = archivos_traduccion($traduccion);
    $paquete = crear_paquete_traduccion($traduccion, $archivos);
    $zip = new ZipArchive();
    $abierto = $zip->open($paquete['ruta']) === true;
    $valido = $valido &&
        $idioma === $idiomaEsperado &&
        count($archivos) === $esperado['archivos'] &&
        $abierto;
    $manifiesto = $abierto
        ? json_decode((string)$zip->getFromName('manifiesto.json'), true)
        : null;
    $valido = $valido && is_array($manifiesto) &&
        ($manifiesto['version_contrato'] ?? 0) === 1 &&
        ($manifiesto['idioma'] ?? '') === $idiomaEsperado &&
        ($manifiesto['version'] ?? 0) === $esperado['version'] &&
        count($manifiesto['archivos'] ?? []) === count($archivos);
    foreach ($archivos as $indice => $archivo) {
        $archivoManifiesto = $manifiesto['archivos'][$indice] ?? null;
        $contenidoSql = $zip->getFromName($archivo['nombre']);
        $valido = $valido && is_array($archivoManifiesto) &&
            is_string($contenidoSql) &&
            ($archivoManifiesto['nombre'] ?? '') === $archivo['nombre'] &&
            ($archivoManifiesto['tamano'] ?? -1) ===
                strlen($contenidoSql) &&
            ($archivoManifiesto['sha256'] ?? '') ===
                hash('sha256', $contenidoSql);
    }
    $indiceCatalogo = in_array(
        $idiomaEsperado,
        ['ca-ES', 'en-GB'],
        true
    ) ? 1 : 2;
    $valido = $valido &&
        ($archivos[0]['nombre'] ?? '') ===
            '000_preparar_descarga.sql' &&
        ($archivos[$indiceCatalogo]['tamano'] ?? 0) > 1000000;
    if ($abierto) {
        $zip->close();
    }
    @unlink($paquete['ruta']);
}
if (!$valido) {
    fwrite(STDERR, "ERROR: hay un paquete de traducción no válido.\n");
    exit(1);
}
fwrite(STDOUT, "OK: paquetes y manifiestos de traducción válidos.\n");
