# Servicio central de errores

`soporte_errores_web.sql` crea el esquema de la BBDD central del webservice.
No modifica la BBDD operativa de Factuzam ni `factuzam_original.sql`.

El flujo dispone de estos estados: `NUEVO`, `EN_REVISION`,
`ESPERANDO_CLIENTE`, `RESPONDIDO`, `RESUELTO` y `CERRADO`. Cada cambio queda
registrado en `soporte_error_estados`; las conversaciones se guardan en
`soporte_error_comunicaciones` y los binarios permanecen fuera de la BBDD con
sus metadatos en `soporte_error_adjuntos`.

El endpoint público no exige una API ni un nivel de servicio válidos. Su
protección se basa en límites de tamaño, validación de tipos, nombres de
archivo generados por el servidor y límite de peticiones por IP.

Como alternativa al LOG, el cliente puede adjuntar un ZIP con una copia
`.crypt`. El SQL se comprime antes de cifrarse y el formato nuevo conserva la
restauración de las copias cifradas anteriores. Cuando se adjunta la copia no
se envía ni se muestra información del LOG. La contraseña no viaja al
webservice ni se guarda en la BBDD: el usuario debe remitirla por correo a
`info@veryverifactu.com` indicando la referencia recibida.
