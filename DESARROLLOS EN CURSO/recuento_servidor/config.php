<?php
// ============================================================================
//  Configuración del servidor de recuentos. Rellena con tus credenciales de
//  DreamHost. NO lo subas a repos públicos (este es una plantilla de ejemplo).
// ============================================================================
declare(strict_types=1);

define('CFG_DB_HOST', 'mysql.tudominio.com');
define('CFG_DB_NAME', 'factuzam_recuentos');
define('CFG_DB_USER', 'usuario_bbdd');
define('CFG_DB_PASS', 'password_bbdd');

// Clave maestra para Factuzam (cabecera X-API-Key de inv_enviar / inv_recoger
// / inv_almacenes_sync / inv_pendientes / inv_estado).
define('CFG_API_KEY', 'CAMBIA-ESTA-CLAVE-MAESTRA');

// Clave de alta para que un dispositivo nuevo se registre (disp_registrar.php).
define('CFG_CLAVE_ALTA', 'CAMBIA-ESTA-CLAVE-DE-ALTA');
