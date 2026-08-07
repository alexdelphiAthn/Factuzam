# Servidor PHP de FzamControlU

Estos endpoints se instalan en el mismo servidor de la red interna que accede
a la base de datos de Factuzam. El teléfono nunca se conecta directamente a
MariaDB/MySQL.

## Instalación

1. Requiere PHP 8.1 o posterior con `pdo_mysql` y acceso de lectura a la base
   de datos Factuzam.
2. Configura como `DocumentRoot` únicamente la carpeta `publico`. La carpeta
   `privado` no debe publicarse.
3. Copia `privado/config.php.example` como `privado/config.php`, completa la
   conexión, genera un secreto de token distinto y configura como
   `CFG_FOTOS_DIRECTORIO` la raíz de `appDirFotos` (la que contiene `300`). El
   proceso PHP debe poder escribir en `CFG_LOGIN_RATE_LIMIT_DIRECTORIO`.
4. En la app indica la URL que corresponde a `publico`, por ejemplo
   `https://stock.intranet.local/fzamcontrolu` o
   `http://192.168.1.20/fzamcontrolu`.

Permisos mínimos orientativos para el usuario de base de datos:

```sql
GRANT SELECT ON Factuzam.fza_usuarios TO 'fzamcontrolu'@'servidor-web';
GRANT SELECT ON Factuzam.fza_usuarios_grupos TO 'fzamcontrolu'@'servidor-web';
GRANT SELECT ON Factuzam.fza_permisos TO 'fzamcontrolu'@'servidor-web';
GRANT SELECT ON Factuzam.fza_articulos TO 'fzamcontrolu'@'servidor-web';
GRANT SELECT ON Factuzam.fza_articulos_skus TO 'fzamcontrolu'@'servidor-web';
GRANT SELECT ON Factuzam.fza_codigos_barras TO 'fzamcontrolu'@'servidor-web';
GRANT SELECT ON Factuzam.fza_articulos_fotos TO 'fzamcontrolu'@'servidor-web';
GRANT UPDATE (ULTIMO_LOGIN_USU) ON Factuzam.fza_usuarios
  TO 'fzamcontrolu'@'servidor-web';
GRANT EXECUTE ON PROCEDURE Factuzam.PRC_GET_CAJA_STOCK_PIVOTADO
  TO 'fzamcontrolu'@'servidor-web';
```

El procedimiento se ejecuta con la seguridad definida en la instalación de
Factuzam. Si allí está configurado como `SQL SECURITY INVOKER`, habrá que
conceder también lectura sobre las tablas que utiliza para calcular el stock.
La actualización de `ULTIMO_LOGIN_USU` puede desactivarse con
`CFG_ACTUALIZAR_ULTIMO_LOGIN=false` si se prefiere una cuenta estrictamente de
solo lectura.

Apache debe conservar la cabecera `Authorization`; se incluye `.htaccess`. En
Nginx/FastCGI se debe mantener `fastcgi_param HTTP_AUTHORIZATION
$http_authorization;`.

## Contrato

- `POST login.php`: JSON `usuario` y `password`; devuelve `token` y
  `expira_en` dentro de `datos`.
- `GET stock.php?articulo=...`: acepta artículo, SKU o código de barras y exige
  `Authorization: Bearer ...`.
- `GET foto.php?articulo=...&unidad=...`: devuelve el PNG de 300 px con el
  mismo Bearer. La URL la genera `stock.php`; no se aceptan rutas de disco.

`stock.php` y `foto.php` respetan `menu.mnuConsultaStocks` con la misma
precedencia que Factuzam: usuario, grupo y `Todos`; los grupos administradores
omiten la restricción y la ausencia de una regla permite el acceso.

La contraseña se compara con el MD5 heredado que ya usa Factuzam. No es un
mecanismo moderno: el endpoint no empeora el formato existente, pero se
recomienda migrar las contraseñas cuando la aplicación principal lo permita.

Aunque el servidor esté en la LAN, se recomienda HTTPS. Con HTTP el usuario,
la contraseña y el token pueden verse desde la red local.

El login limita por defecto los intentos por `REMOTE_ADDR` y responde `429`
al superar el umbral. Si hay un proxy inverso, configura allí un límite
equivalente usando la IP real; desactiva el límite PHP únicamente cuando el
proxy ya lo aplique, porque el endpoint no confía en cabeceras reenviadas.

## Verificación

Desde la raíz `servidor_php`:

```sh
php tests/pruebas.php
php -l publico/login.php
php -l publico/stock.php
php -l publico/foto.php
```
