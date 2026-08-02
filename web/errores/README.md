# Consola de errores de Factuzam

El receptor público es `/error.php` y no exige una API válida. La consola del
desarrollador vive en `/errores/` y usa autenticación HTTP Basic configurada en
el servidor. El seguimiento del cliente se hace mediante una referencia y un
token aleatorio que solo se devuelven al crear la incidencia.

Todo el servicio debe publicarse exclusivamente mediante HTTPS.

## Configuración

1. Aplicar `DESARROLLOS EN CURSO/soporte_errores_web.sql` a una BBDD MariaDB
   central.
2. Definir estas variables del entorno de PHP:

   - `FACTUZAM_ERROR_DSN`, por ejemplo
     `mysql:host=127.0.0.1;dbname=factuzam_soporte;charset=utf8mb4`.
   - `FACTUZAM_ERROR_DB_USER` y `FACTUZAM_ERROR_DB_PASS`.
   - `FACTUZAM_ERROR_STORAGE`, directorio privado fuera del DocumentRoot.
   - `FACTUZAM_ERROR_PUBLIC_URL`, por ejemplo
     `https://webservice.veryverifactu.com`.
   - `FACTUZAM_ERROR_ADMIN_USER` y `FACTUZAM_ERROR_ADMIN_PASS`.
   - `FACTUZAM_ERROR_DEVELOPER_EMAIL` para avisos de nuevas incidencias.
   - `FACTUZAM_ERROR_FROM` como remitente de las respuestas.

El servidor debe admitir peticiones de 220 MiB y PHP debe tener configurados
`post_max_size` y `upload_max_filesize` de forma coherente. También debe tener
habilitados PDO MySQL, Fileinfo, ZipArchive y el envío de correo. Los adjuntos
no se sirven directamente
desde el servidor web: `adjunto.php` comprueba la sesión de administrador y que
la ruta permanezca dentro del almacén privado.

La copia de seguridad es opcional y sustituye al LOG. El ZIP contiene una copia
`.crypt` protegida mediante la contraseña elegida por el cliente. La contraseña
no se envía al servicio ni se guarda: tras recibir la referencia, Factuzam pide
al usuario que la remita a `info@veryverifactu.com` indicando esa referencia.

## Estados

`NUEVO`, `EN_REVISION`, `ESPERANDO_CLIENTE`, `RESPONDIDO`, `RESUELTO` y
`CERRADO`. La consola conserva el historial completo de cambios y mensajes.
