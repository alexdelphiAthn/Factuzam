<?php
declare(strict_types=1);

require_once __DIR__ . '/errores/lib.php';

const MAXIMO_PETICION = 220 * 1024 * 1024;
const MAXIMO_PANTALLAZO = 8 * 1024 * 1024;
const MAXIMO_LOG = 10 * 1024 * 1024;
const MAXIMO_COPIA_SEGURIDAD = 200 * 1024 * 1024;
const MAXIMO_ERRORES_IP_HORA = 20;

function validar_telefono(string $telefono): bool
{
    if (preg_match('/[^0-9+ .()\-]/', $telefono)) {
        return false;
    }
    $digitos = preg_replace('/\D+/', '', $telefono) ?? '';
    return strlen($digitos) >= 7 && strlen($digitos) <= 15;
}

function comprobar_limite_ip(PDO $db, string $ip): void
{
    $sql = 'SELECT COUNT(*) FROM soporte_errores ' .
        'WHERE IP_ORIGEN = :ip ' .
        'AND INSTANTE_ALTA >= UTC_TIMESTAMP() - INTERVAL 1 HOUR';
    $consulta = $db->prepare($sql);
    $consulta->execute([':ip' => $ip]);
    if ((int)$consulta->fetchColumn() >= MAXIMO_ERRORES_IP_HORA) {
        responder_json(429, [
            'ok' => false,
            'message' => 'Demasiados envíos. Inténtelo más tarde.',
        ]);
    }
}

function validar_zip_copia_seguridad(string $ruta): void
{
    if (!class_exists('ZipArchive')) {
        throw new RuntimeException('El servidor no puede validar el ZIP.');
    }
    $firma = file_get_contents($ruta, false, null, 0, 4);
    if ($firma !== "PK\x03\x04") {
        throw new RuntimeException('La copia no es un ZIP válido.');
    }
    $zip = new ZipArchive();
    if ($zip->open($ruta) !== true) {
        throw new RuntimeException('No se pudo abrir el ZIP de la copia.');
    }
    try {
        if ($zip->numFiles !== 1) {
            throw new RuntimeException('El ZIP de la copia no es válido.');
        }
        $nombre = (string)$zip->getNameIndex(0);
        if ($nombre === '' || basename($nombre) !== $nombre ||
            !str_ends_with(strtolower($nombre), '.crypt')) {
            throw new RuntimeException('El ZIP no contiene una copia válida.');
        }
        $datos = $zip->statIndex(0);
        if (!is_array($datos) || (int)($datos['size'] ?? 0) <= 0) {
            throw new RuntimeException('La copia cifrada está vacía.');
        }
        $flujo = $zip->getStream($nombre);
        if (!is_resource($flujo)) {
            throw new RuntimeException('No se pudo leer la copia cifrada.');
        }
        $cabecera = (string)fread($flujo, 64);
        fclose($flujo);
        $cabecera = preg_replace('/^\xEF\xBB\xBF/', '', $cabecera) ?? '';
        if (!str_starts_with($cabecera, 'FZAM_COPIA_CIFRADA_V2') &&
            !str_starts_with($cabecera, 'FZAM_COPIA_CIFRADA_V3')) {
            throw new RuntimeException('La copia cifrada no es válida.');
        }
    } finally {
        $zip->close();
    }
}

function preparar_adjunto(
    string $campo,
    string $tipo,
    int $maximo,
    string $directorio,
    string $nombreDestino,
    array $mimes
): ?array {
    if (!isset($_FILES[$campo]) ||
        (int)$_FILES[$campo]['error'] === UPLOAD_ERR_NO_FILE) {
        return null;
    }
    $archivo = $_FILES[$campo];
    if ((int)$archivo['error'] !== UPLOAD_ERR_OK) {
        throw new RuntimeException('No se recibió correctamente ' . $campo);
    }
    $tamano = (int)$archivo['size'];
    if ($tamano <= 0 || $tamano > $maximo) {
        throw new RuntimeException('Tamaño no válido para ' . $campo);
    }
    $temporal = (string)$archivo['tmp_name'];
    if (!is_uploaded_file($temporal)) {
        throw new RuntimeException('Adjunto no válido.');
    }
    $finfo = new finfo(FILEINFO_MIME_TYPE);
    $mime = (string)$finfo->file($temporal);
    if (!in_array($mime, $mimes, true)) {
        throw new RuntimeException('Tipo no válido para ' . $campo);
    }
    if ($tipo === 'PANTALLAZO') {
        $imagen = @getimagesize($temporal);
        if (!is_array($imagen) || ($imagen[2] ?? 0) !== IMAGETYPE_PNG) {
            throw new RuntimeException('El pantallazo no es un PNG válido.');
        }
    }
    if ($tipo === 'COPIA_SEGURIDAD') {
        validar_zip_copia_seguridad($temporal);
    }
    asegurar_directorio($directorio);
    $destino = $directorio . DIRECTORY_SEPARATOR . $nombreDestino;
    if (!move_uploaded_file($temporal, $destino)) {
        throw new RuntimeException('No se pudo guardar el adjunto.');
    }
    chmod($destino, 0640);
    return [
        'tipo' => $tipo,
        'nombre' => basename((string)$archivo['name']),
        'ruta' => $destino,
        'mime' => $mime,
        'tamano' => filesize($destino),
        'sha256' => hash_file('sha256', $destino),
    ];
}

function insertar_error(
    PDO $db,
    array $datos,
    string $referencia,
    string $token,
    string $ip
): int {
    $sql = 'INSERT INTO soporte_errores (' .
        'REFERENCIA_ERROR, TOKEN_SEGUIMIENTO_HASH, REFERENCIA_CLIENTE, ' .
        'APLICACION, VERSION_APLICACION, USUARIO_CLIENTE, GRUPO_CLIENTE, ' .
        'EMPRESA_CLIENTE, ALMACEN_CLIENTE, CAJA_CLIENTE, EQUIPO_CLIENTE, ' .
        'MODO_LICENCIA, ESTADO_LICENCIA, ' .
        'EMAIL_CONTACTO, TELEFONO_CONTACTO, DESCRIPCION_CLIENTE, ' .
        'CLASE_ERROR, MENSAJE_ERROR, DETALLE_ERROR, ESLOG_SQL, ' .
        'ESLOG_RENDIMIENTO, ESLOG_AVANZADO, ESLOG_COMPLETO, ESTADO_ERROR, ' .
        'IP_ORIGEN, USER_AGENT, USUARIO_ALTA, USUARIO_MODIF) VALUES (' .
        ':referencia, :token, :referencia_cliente, :aplicacion, :version, ' .
        ':usuario, :grupo, :empresa, :almacen, :caja, :equipo, ' .
        ':modo_licencia, :estado_licencia, :email, :telefono, ' .
        ':descripcion, :clase_error, :mensaje_error, ' .
        ':detalle_error, :log_sql, :log_rendimiento, :log_avanzado, ' .
        ':log_completo, :estado, :ip, :agente, :usuario_alta, ' .
        ':usuario_modif)';
    $consulta = $db->prepare($sql);
    $consulta->execute([
        ':referencia' => $referencia,
        ':token' => hash_token($token),
        ':referencia_cliente' => $datos['referencia_cliente'],
        ':aplicacion' => $datos['aplicacion'],
        ':version' => $datos['version'],
        ':usuario' => $datos['usuario'],
        ':grupo' => $datos['grupo'],
        ':empresa' => $datos['empresa'],
        ':almacen' => $datos['almacen'],
        ':caja' => $datos['caja'],
        ':equipo' => $datos['equipo'],
        ':modo_licencia' => $datos['modo_licencia'],
        ':estado_licencia' => $datos['estado_licencia'],
        ':email' => $datos['email'],
        ':telefono' => $datos['telefono'],
        ':descripcion' => $datos['descripcion'],
        ':clase_error' => $datos['clase_error'],
        ':mensaje_error' => $datos['mensaje_error'],
        ':detalle_error' => $datos['detalle_error'],
        ':log_sql' => $datos['log_sql'],
        ':log_rendimiento' => $datos['log_rendimiento'],
        ':log_avanzado' => $datos['log_avanzado'],
        ':log_completo' => $datos['log_completo'],
        ':estado' => 'NUEVO',
        ':ip' => $ip,
        ':agente' => limpiar_texto($_SERVER['HTTP_USER_AGENT'] ?? '', 500),
        ':usuario_alta' => 'CLIENTE',
        ':usuario_modif' => 'CLIENTE',
    ]);
    return (int)$db->lastInsertId();
}

function insertar_adjunto(PDO $db, int $idError, array $adjunto): void
{
    $sql = 'INSERT INTO soporte_error_adjuntos (' .
        'ID_ERROR, TIPO_ADJUNTO, NOMBRE_ORIGINAL, RUTA_PRIVADA, TIPO_MIME, ' .
        'TAMANO_BYTES, SHA256_ADJUNTO, USUARIO_ALTA, USUARIO_MODIF) VALUES (' .
        ':id, :tipo, :nombre, :ruta, :mime, :tamano, :sha256, ' .
        ':usuario_alta, :usuario_modif)';
    $consulta = $db->prepare($sql);
    $consulta->execute([
        ':id' => $idError,
        ':tipo' => $adjunto['tipo'],
        ':nombre' => $adjunto['nombre'],
        ':ruta' => $adjunto['ruta'],
        ':mime' => $adjunto['mime'],
        ':tamano' => $adjunto['tamano'],
        ':sha256' => $adjunto['sha256'],
        ':usuario_alta' => 'CLIENTE',
        ':usuario_modif' => 'CLIENTE',
    ]);
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    responder_json(405, [
        'ok' => false,
        'message' => 'Método no permitido.',
    ]);
}

$longitud = (int)($_SERVER['CONTENT_LENGTH'] ?? 0);
if ($longitud <= 0 || $longitud > MAXIMO_PETICION) {
    responder_json(413, [
        'ok' => false,
        'message' => 'El envío está vacío o supera el tamaño permitido.',
    ]);
}

$datos = [
    'referencia_cliente' => limpiar_texto($_POST['referencia_cliente'] ?? '', 120),
    'aplicacion' => limpiar_texto($_POST['aplicacion'] ?? '', 80),
    'version' => limpiar_texto($_POST['version'] ?? '', 40),
    'usuario' => limpiar_texto($_POST['usuario'] ?? '', 100),
    'grupo' => limpiar_texto($_POST['grupo'] ?? '', 100),
    'empresa' => limpiar_texto($_POST['empresa'] ?? '', 100),
    'almacen' => limpiar_texto($_POST['almacen'] ?? '', 100),
    'caja' => limpiar_texto($_POST['caja'] ?? '', 100),
    'equipo' => limpiar_texto($_POST['equipo'] ?? '', 255),
    'modo_licencia' => limpiar_texto($_POST['modo_licencia'] ?? 'DEMO', 20),
    'estado_licencia' => limpiar_texto(
        $_POST['estado_licencia'] ?? 'DESCONOCIDA',
        30
    ),
    'email' => limpiar_texto($_POST['email'] ?? '', 254),
    'telefono' => limpiar_texto($_POST['telefono'] ?? '', 50),
    'descripcion' => limpiar_texto($_POST['descripcion'] ?? '', 10000),
    'clase_error' => limpiar_texto($_POST['clase_error'] ?? '', 255),
    'mensaje_error' => limpiar_texto($_POST['mensaje_error'] ?? '', 20000),
    'detalle_error' => limpiar_texto($_POST['detalle_error'] ?? '', 500000),
    'log_sql' => valor_sn($_POST['log_sql'] ?? ''),
    'log_rendimiento' => valor_sn($_POST['log_rendimiento'] ?? ''),
    'log_avanzado' => valor_sn($_POST['log_avanzado'] ?? ''),
    'log_completo' => valor_sn($_POST['log_completo'] ?? ''),
];

$copiaSolicitada = isset($_FILES['copia_seguridad']) &&
    (int)$_FILES['copia_seguridad']['error'] !== UPLOAD_ERR_NO_FILE;
if ($copiaSolicitada) {
    $datos['log_sql'] = 'N';
    $datos['log_rendimiento'] = 'N';
    $datos['log_avanzado'] = 'N';
    $datos['log_completo'] = 'N';
}

if (!in_array($datos['modo_licencia'], ['REGISTRADA', 'DEMO'], true)) {
    $datos['modo_licencia'] = 'DEMO';
}

if ($datos['aplicacion'] === '' || $datos['version'] === '' ||
    $datos['clase_error'] === '' || $datos['mensaje_error'] === '' ||
    $datos['detalle_error'] === '') {
    responder_json(400, [
        'ok' => false,
        'message' => 'Faltan los datos técnicos del error.',
    ]);
}
if (!filter_var($datos['email'], FILTER_VALIDATE_EMAIL) ||
    !validar_telefono($datos['telefono'])) {
    responder_json(400, [
        'ok' => false,
        'message' => 'El email o el teléfono no son válidos.',
    ]);
}

$db = null;
$directorio = '';
try {
    $db = bbdd();
    $ip = limpiar_texto($_SERVER['REMOTE_ADDR'] ?? '', 45);
    comprobar_limite_ip($db, $ip);
    $referencia = generar_referencia_error();
    $token = generar_token_seguimiento();
    $directorio = ruta_almacen_privado() . DIRECTORY_SEPARATOR .
        gmdate('Y') . DIRECTORY_SEPARATOR . gmdate('m') .
        DIRECTORY_SEPARATOR . $referencia;
    $db->beginTransaction();
    $idError = insertar_error($db, $datos, $referencia, $token, $ip);
    $pantallazo = preparar_adjunto(
        'pantallazo',
        'PANTALLAZO',
        MAXIMO_PANTALLAZO,
        $directorio,
        'pantallazo.png',
        ['image/png']
    );
    $copiaSeguridad = preparar_adjunto(
        'copia_seguridad',
        'COPIA_SEGURIDAD',
        MAXIMO_COPIA_SEGURIDAD,
        $directorio,
        'copia_seguridad.zip',
        ['application/zip', 'application/x-zip-compressed',
            'application/octet-stream']
    );
    $log = null;
    if (!is_array($copiaSeguridad)) {
        $log = preparar_adjunto(
            'log',
            'LOG',
            MAXIMO_LOG,
            $directorio,
            'factuzam.log',
            ['text/plain', 'application/octet-stream']
        );
    }
    if (is_array($pantallazo)) {
        insertar_adjunto($db, $idError, $pantallazo);
    }
    if (is_array($log)) {
        insertar_adjunto($db, $idError, $log);
    }
    if (is_array($copiaSeguridad)) {
        insertar_adjunto($db, $idError, $copiaSeguridad);
    }
    registrar_estado($db, $idError, null, 'NUEVO', 'CLIENTE');
    $db->commit();
    $url = url_seguimiento($referencia, $token);
    notificar_desarrollador(
        $referencia,
        $datos['clase_error'] . ': ' . $datos['mensaje_error'] . "\n" .
        'Cliente: ' . $datos['referencia_cliente'] . "\n" .
        'Contacto: ' . $datos['email'] . ' / ' . $datos['telefono'] . "\n" .
        'Copia de seguridad: ' .
        (is_array($copiaSeguridad) ? 'adjunta' : 'no adjunta')
    );
    responder_json(201, [
        'ok' => true,
        'referencia' => $referencia,
        'token_seguimiento' => $token,
        'url_seguimiento' => $url,
        'message' => 'Error recibido correctamente.',
    ]);
} catch (Throwable $error) {
    if ($db instanceof PDO && $db->inTransaction()) {
        $db->rollBack();
    }
    if ($directorio !== '' && is_dir($directorio)) {
        foreach (glob($directorio . DIRECTORY_SEPARATOR . '*') ?: [] as $ruta) {
            if (is_file($ruta)) {
                @unlink($ruta);
            }
        }
        @rmdir($directorio);
    }
    error_log('error.php: ' . $error->getMessage());
    responder_json(500, [
        'ok' => false,
        'message' => 'No se pudo registrar el error. Inténtelo de nuevo.',
    ]);
}
