<?php
declare(strict_types=1);

use PHPMailer\PHPMailer\PHPMailer;

require_once __DIR__ . '/autenticacion.php';

const CORREO_MAX_DOCUMENTOS = 8;
const CORREO_MAX_DOCUMENTO_BYTES = 5 * 1024 * 1024;
const CORREO_MAX_TOTAL_BYTES = 15 * 1024 * 1024;

final class ConfiguracionCorreoException extends RuntimeException
{
}

final class DependenciaCorreoException extends RuntimeException
{
}

final class EnvioCorreoException extends RuntimeException
{
}

function registrar_evento_correo(
    string $referencia,
    string $etapa,
    string $mensaje
): void {
    $directorio = __DIR__ . '/logs';
    $ruta = $directorio . '/correo.log';
    $texto = preg_replace('/[\r\n\t]+/', ' ', trim($mensaje)) ?? '';
    $linea = gmdate('Y-m-d\TH:i:s\Z') .
        ' peticion=' . id_peticion() .
        ' referencia=' . $referencia .
        ' etapa=' . $etapa .
        ' mensaje=' . $texto . PHP_EOL;
    if (!is_dir($directorio)) {
        @mkdir($directorio, 0700, true);
    }
    $existia = is_file($ruta);
    $escrito = @file_put_contents($ruta, $linea, FILE_APPEND | LOCK_EX);
    if ($escrito !== false && !$existia) {
        @chmod($ruta, 0600);
    }
    if ($escrito === false) {
        error_log('CertApiWeb correo: no se pudo escribir ' . $ruta);
    }
}

function registrar_error_correo(
    Throwable $error,
    string $referencia,
    string $etapa
): void {
    registrar_error_servidor($error);
    registrar_evento_correo(
        $referencia,
        $etapa,
        get_class($error) . ': ' . $error->getMessage()
    );
}

function configuracion_smtp_referencia(string $referencia): array
{
    static $configuraciones = null;
    if ($configuraciones === null) {
        $ruta = __DIR__ . '/correos_config.php';
        if (!is_file($ruta)) {
            throw new ConfiguracionCorreoException(
                'No existe el fichero privado de configuración SMTP.'
            );
        }
        $configuraciones = require $ruta;
        if (!is_array($configuraciones)) {
            throw new ConfiguracionCorreoException(
                'El fichero privado de configuración SMTP no es válido.'
            );
        }
    }
    $configuracion = $configuraciones[$referencia] ?? null;
    if (!is_array($configuracion)) {
        throw new ConfiguracionCorreoException(
            'La instalación no tiene configurada una cuenta SMTP.'
        );
    }
    $obligatorios = [
        'host',
        'puerto',
        'seguridad',
        'usuario',
        'password',
        'email_remitente',
        'nombre_remitente'
    ];
    foreach ($obligatorios as $campo) {
        if (!array_key_exists($campo, $configuracion)) {
            throw new ConfiguracionCorreoException(
                'La configuración SMTP de la instalación está incompleta.'
            );
        }
    }
    $puerto = (int)$configuracion['puerto'];
    $seguridad = strtolower(trim((string)$configuracion['seguridad']));
    $usuario = trim((string)$configuracion['usuario']);
    $remitente = trim((string)$configuracion['email_remitente']);
    if ($puerto < 1 || $puerto > 65535 ||
        !in_array($seguridad, ['tls', 'ssl'], true) ||
        filter_var($usuario, FILTER_VALIDATE_EMAIL) === false ||
        filter_var($remitente, FILTER_VALIDATE_EMAIL) === false ||
        trim((string)$configuracion['password']) === '') {
        throw new ConfiguracionCorreoException(
            'La configuración SMTP de la instalación no es válida.'
        );
    }
    return $configuracion;
}

function cargar_phpmailer(): void
{
    $autoload = __DIR__ . '/vendor/autoload.php';
    if (!is_file($autoload)) {
        throw new DependenciaCorreoException(
            'PHPMailer no está instalado en el directorio privado.'
        );
    }
    require_once $autoload;
}

function documentos_pdf_subidos(array $archivo): array
{
    $nombres = $archivo['name'] ?? [];
    $temporales = $archivo['tmp_name'] ?? [];
    $errores = $archivo['error'] ?? [];
    $tamanos = $archivo['size'] ?? [];
    if (!is_array($nombres)) {
        $nombres = [$nombres];
        $temporales = [$temporales];
        $errores = [$errores];
        $tamanos = [$tamanos];
    }
    $cantidad = count($nombres);
    if ($cantidad < 1 || $cantidad > CORREO_MAX_DOCUMENTOS ||
        count($temporales) !== $cantidad || count($errores) !== $cantidad ||
        count($tamanos) !== $cantidad) {
        responder_error(
            'DOCUMENTOS_INVALIDOS',
            'La cantidad de documentos adjuntos no es válida.',
            422
        );
    }
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    if ($finfo === false) {
        responder_error(
            'VALIDACION_PDF_NO_DISPONIBLE',
            'No se pueden validar los documentos PDF.',
            500
        );
    }
    $resultado = [];
    $total = 0;
    try {
        for ($i = 0; $i < $cantidad; $i++) {
            $temporal = is_string($temporales[$i]) ? $temporales[$i] : '';
            $tamano = is_int($tamanos[$i]) ? $tamanos[$i] : 0;
            if ((int)$errores[$i] !== UPLOAD_ERR_OK ||
                $temporal === '' || !is_uploaded_file($temporal) ||
                $tamano < 1 || $tamano > CORREO_MAX_DOCUMENTO_BYTES) {
                responder_error(
                    'DOCUMENTO_INVALIDO',
                    'Uno de los documentos no es válido o supera 5 MB.',
                    413
                );
            }
            $total += $tamano;
            if ($total > CORREO_MAX_TOTAL_BYTES) {
                responder_error(
                    'DOCUMENTOS_DEMASIADO_GRANDES',
                    'Los documentos superan el tamaño total permitido.',
                    413
                );
            }
            $mime = finfo_file($finfo, $temporal);
            $manejador = fopen($temporal, 'rb');
            $firma = $manejador === false ? '' : (string)fread($manejador, 5);
            if (is_resource($manejador)) {
                fclose($manejador);
            }
            if ($mime !== 'application/pdf' || $firma !== '%PDF-') {
                responder_error(
                    'DOCUMENTO_NO_PDF',
                    'Todos los documentos adjuntos deben ser PDF válidos.',
                    422
                );
            }
            $nombre = is_string($nombres[$i]) ? basename($nombres[$i]) : '';
            $nombre = preg_replace('/[^A-Za-z0-9._-]/', '_', $nombre) ?? '';
            if ($nombre === '') {
                $nombre = 'documento_' . ($i + 1) . '.pdf';
            }
            if (strtolower(pathinfo($nombre, PATHINFO_EXTENSION)) !== 'pdf') {
                $nombre .= '.pdf';
            }
            $resultado[] = [
                'ruta' => $temporal,
                'nombre' => $nombre
            ];
        }
    } finally {
        finfo_close($finfo);
    }
    return $resultado;
}

function enviar_documentacion_ticket(
    array $configuracion,
    string $destinatario,
    string $asunto,
    string $cuerpo,
    array $documentos
): void {
    cargar_phpmailer();
    $correo = new PHPMailer(true);
    $correo->CharSet = 'UTF-8';
    $correo->isSMTP();
    $correo->Host = trim((string)$configuracion['host']);
    $correo->Port = (int)$configuracion['puerto'];
    $correo->SMTPAuth = true;
    $correo->Username = trim((string)$configuracion['usuario']);
    $correo->Password = (string)$configuracion['password'];
    $correo->SMTPSecure =
        strtolower(trim((string)$configuracion['seguridad'])) === 'ssl'
        ? PHPMailer::ENCRYPTION_SMTPS
        : PHPMailer::ENCRYPTION_STARTTLS;
    $correo->SMTPAutoTLS = true;
    $correo->Timeout = 30;
    $correo->setFrom(
        trim((string)$configuracion['email_remitente']),
        trim((string)$configuracion['nombre_remitente'])
    );
    $correo->addAddress($destinatario);
    $correo->Subject = $asunto;
    $correo->Body = $cuerpo;
    $correo->isHTML(false);
    foreach ($documentos as $documento) {
        $correo->addAttachment($documento['ruta'], $documento['nombre']);
    }
    try {
        $correo->send();
    } catch (Throwable $error) {
        throw new EnvioCorreoException(
            'El servidor SMTP no ha aceptado el envío.',
            0,
            $error
        );
    }
}
