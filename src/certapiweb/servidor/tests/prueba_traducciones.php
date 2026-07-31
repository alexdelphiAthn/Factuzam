<?php
declare(strict_types=1);

require dirname(__DIR__) . '/privado/traducciones.php';

$idioma = normalizar_idioma_traduccion('zh-cn');
$traduccion = obtener_traduccion($idioma);
$archivos = archivos_traduccion($traduccion);
$paquete = crear_paquete_traduccion($traduccion, $archivos);
$zip = new ZipArchive();
$valido = $idioma === 'zh-CN' &&
    count($archivos) === 1 &&
    $zip->open($paquete['ruta']) === true;
$manifiesto = $valido
    ? json_decode((string)$zip->getFromName('manifiesto.json'), true)
    : null;
$contenidoSql = $valido
    ? $zip->getFromName('001_menu_principal.sql')
    : false;
$archivoManifiesto = is_array($manifiesto)
    ? ($manifiesto['archivos'][0] ?? null)
    : null;
$valido = $valido && is_array($manifiesto) &&
    in_array('descargar:traducciones', CFG_AMBITOS_PERMITIDOS, true) &&
    ($manifiesto['version_contrato'] ?? 0) === 1 &&
    ($manifiesto['idioma'] ?? '') === 'zh-CN' &&
    count($manifiesto['archivos'] ?? []) === 1 &&
    is_array($archivoManifiesto) && is_string($contenidoSql) &&
    ($archivoManifiesto['tamano'] ?? -1) === strlen($contenidoSql) &&
    ($archivoManifiesto['sha256'] ?? '') === hash('sha256', $contenidoSql);
$zip->close();
@unlink($paquete['ruta']);
if (!$valido) {
    fwrite(STDERR, "ERROR: el paquete de traducción no es válido.\n");
    exit(1);
}
fwrite(STDOUT, "OK: paquete zh-CN y manifiesto válidos.\n");
