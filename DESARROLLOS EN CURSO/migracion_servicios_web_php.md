# Migración y unificación de los servicios web PHP

> Estado: migración iniciada. El núcleo de autenticación, la obtención del
> número SIF y la primera API de fotos están implementados en `certapiweb`.

## 1. Objetivo

Unificar los servicios web propios de Factuzam bajo una API versionada, con un
único núcleo de configuración, autenticación, autorización, respuestas y
auditoría.

La unificación afecta a dos lados:

- **Servidor PHP**: todos los endpoints reutilizan el mismo arranque y las
  mismas comprobaciones de seguridad.
- **Factuzam y aplicaciones auxiliares**: todas las llamadas utilizan un
  cliente HTTP común y una credencial única por instalación.

No se pretende convertir todos los servicios en un único fichero PHP ni mover
de inmediato todos los datos a una misma BBDD. Se unifican la puerta de
entrada, la identidad y las reglas comunes, manteniendo cada dominio separado.

## 2. Alcance

Incluido en esta migración:

- Registro y número de instalación SIF.
- Subida, consulta, listado y descarga de fotos.
- Recuentos de inventario y dispositivos de recuento.
- Nuevo servicio de sincronización y consulta de ventas.
- Cliente HTTP común en Factuzam.
- Autenticación de aplicaciones móviles y usuarios.

Fuera de alcance:

- Servicios externos de la AEAT, PrestaShop u otros proveedores.
- Sustituir UniDAC, `THTTPClient` o el almacenamiento actual de fotos.
- Trasladar de una vez toda la BBDD de recuentos.
- Modificar `factuzam_original.sql`.

## 3. Inventario actual

### 3.1 Instalación SIF

| Elemento | Situación actual |
|---|---|
| Servidor | `web/api/instalacion.php`. |
| Método | `POST` JSON. |
| Consumidor | `src/verifactu/inLibVerifactuInstalacion.pas`. |
| Autenticación | No tiene autenticación. |
| Persistencia | Ficheros JSON y log fuera de `web/`. |
| Datos | Versión, razón social, NIF, código SIF, IP y agente de usuario. |

La clave lógica antigua incluía la versión de Factuzam. Se ha corregido el
diseño para conservar el mismo número de instalación al actualizar la versión.
La identidad global es la referencia asociada a la API; la versión queda como
metadato actualizado de esa instalación.

### 3.2 Fotos

Servicios encontrados:

| Fichero | Función |
|---|---|
| `src/fotos_nube/upload_foto.php` | Subir una foto y generar tamaños. |
| `src/fotos_nube/ver_foto.php` | Consultar y verificar una foto. |
| `src/fotos_nube/oda/upload_foto.php` | Variante ampliada de subida. |
| `src/fotos_nube/oda/ver_foto.php` | Variante ampliada de consulta. |
| `src/fotos_nube/oda/listar_fotos.php` | Inventario de fotos de un cliente. |
| `src/fotos_nube/oda/download_foto.php` | Descargar fotos en ZIP. |
| `src/fotos_nube/oda/indices_helper.php` | Funciones auxiliares de nombres e índices. |

Consumidores principales:

- `src/Lib/inLibFotosNube.pas`.
- `src/fotos_nube/` y sus proyectos auxiliares VCL/FMX.
- Formularios de artículos y sesiones de compra que descargan fotos.

Situación de seguridad:

- Clave `X-API-Key` compartida e incrustada en varios PHP.
- `carpeta_cliente` llega como parámetro de la petición.
- La clave y la carpeta se configuran por separado en Factuzam.
- Hay contratos de error y variantes de scripts diferentes.

Debe confirmarse qué variante está desplegada actualmente. Los ficheros de
`src/fotos_nube/oda/` parecen contener el contrato más completo, pero la
migración no eliminará ninguna variante hasta comprobar producción.

### 3.3 Recuentos

El servidor de recuentos ya dispone de un primer núcleo compartido:

- `DESARROLLOS EN CURSO/recuento_servidor/comun.php`.
- `DESARROLLOS EN CURSO/recuento_servidor/config.php`.

Endpoints para la app:

| Endpoint actual | Función |
|---|---|
| `disp_registrar.php` | Registrar dispositivo y entregar token. |
| `inv_almacenes.php` | Consultar almacenes. |
| `inv_recuentos.php` | Listar o crear recuentos. |
| `inv_catalogo.php` | Descargar catálogo. |
| `inv_eventos.php` | Subir escaneos. |
| `inv_finalizar.php` | Finalizar recuento. |
| `inv_reabrir.php` | Reabrir recuento. |

Endpoints para Factuzam:

| Endpoint actual | Función |
|---|---|
| `inv_enviar.php` | Enviar plantilla y catálogo. |
| `inv_almacenes_sync.php` | Sincronizar almacenes. |
| `inv_pendientes.php` | Listar recuentos pendientes de recoger. |
| `inv_recoger.php` | Recoger eventos y agregado. |
| `inv_estado.php` | Consultar estado. |

Consumidores principales:

- `src/Lib/inLibInventarioNube.pas` desde Factuzam.
- `src/apps_fmx/recuento/RecuentoApi.pas` desde la app móvil.

Situación de seguridad:

- Factuzam usa una clave maestra compartida por todas las instalaciones.
- La app usa un token por dispositivo junto con `X-Carpeta`.
- Los tokens de dispositivo se almacenan directamente en la BBDD.
- La clave de alta de dispositivos también es global.

`comun.php` es el mejor punto de partida para el nuevo núcleo, pero debe dejar
de depender de una clave maestra y de una carpeta elegida por el cliente.

### 3.4 Referencias sin servidor localizado

El proyecto auxiliar de fotos contiene referencias a `generar_backup.php` y
`estado_backup.php`, pero esos ficheros no están en el repositorio. Antes de
cerrar el inventario debe comprobarse si existen únicamente en producción, si
son pruebas o si están retirados.

## 4. Problemas que debe resolver la migración

1. Una clave global filtrada comprometería todos los clientes.
2. La carpeta o cliente se recibe desde la petición en vez de derivarse de la
   identidad autenticada.
3. Hay claves, URLs y formatos de autenticación diferentes por servicio.
4. Algunas claves aparecen incrustadas en el código PHP.
5. No existe una forma central de revocar o rotar una instalación.
6. Los tokens de dispositivos se guardan sin hash.
7. Las respuestas JSON no siguen un único contrato.
8. No hay un identificador común de petición para investigar errores.
9. Los endpoints no tienen una versión de API homogénea.
10. No están centralizados los límites de tamaño, frecuencia y tiempo.
11. El servicio de instalación registra datos personales sin autenticación ni
    una política común de minimización y conservación.

## 5. Arquitectura objetivo

URL lógica propuesta:

```text
https://webservice.veryverifactu.com/api/v1/
├── instalaciones/
├── auth/
├── ventas/
├── recuentos/
└── fotos/
```

La elección definitiva del dominio queda pendiente. Debe evitarse mantener
URLs distintas por cada servicio nuevo.

Flujo general:

```text
Factuzam ──HTTPS──▶ API v1 ──▶ BBDD de identidad
                       ├─────▶ BBDD de recuentos
                       ├─────▶ almacenamiento de fotos
                       └─────▶ BBDD de ventas para consulta
App móvil ──HTTPS──────▲
```

La BBDD de identidad puede ser nueva, por ejemplo `factuzam_api`. La BBDD
`factuzam_recuentos` y el almacenamiento de fotos pueden permanecer como están
durante la primera migración. No es necesario mezclar datos de negocio para
compartir autenticación.

## 6. Identidades y credenciales

### 6.1 Instalación de Factuzam

Cada instalación tendrá una identidad propia:

- Identificador interno de cliente.
- Identificador interno de instalación.
- Número de instalación SIF cuando corresponda.
- Token aleatorio de 32 bytes como mínimo.
- Estado activo o revocado.
- Fecha de alta, último uso y última rotación.
- Permisos o ámbitos autorizados.

Ejemplos de ámbitos:

```text
fotos:leer
fotos:escribir
sif:instalacion
recuentos:leer
recuentos:escribir
ventas:escribir
```

Factuzam enviará la credencial de forma homogénea:

```http
Authorization: Bearer <token-instalacion>
```

El servidor almacenará solamente el hash del token. La copia entregada a la
instalación se mostrará una vez y deberá protegerse en Windows, preferentemente
con DPAPI. No debe quedar en texto claro dentro de un INI.

### 6.2 Usuario móvil

La app de ventas no utilizará el token de la instalación. Cada persona tendrá
su usuario y sus permisos:

- Cliente al que pertenece.
- Empresas y almacenes visibles.
- Rol, por ejemplo administración, dirección o consulta.
- Estado activo o bloqueado.
- Contraseña almacenada mediante `password_hash` y verificada con
  `password_verify`.

El inicio de sesión devolverá:

- Token de acceso de corta duración.
- Token de renovación revocable.
- Identidad y permisos efectivos.

Para la primera versión se recomiendan tokens opacos aleatorios almacenados en
el servidor. Son más sencillos de revocar que un sistema JWT y suficientes
para una API PHP centralizada.

### 6.3 Dispositivo de recuento

Los dispositivos actuales pueden conservar una identidad propia, pero deben
quedar vinculados en servidor al cliente y, cuando proceda, a un usuario. El
token determinará el cliente; `X-Carpeta` dejará de decidirlo.

Durante la transición se podrá recibir `X-Carpeta`, pero solo como dato de
compatibilidad. Si no coincide con el cliente resuelto por el token, la
petición será rechazada.

## 7. Autorización y aislamiento de clientes

La autenticación responde quién llama. La autorización debe comprobar además
qué operación puede realizar.

Reglas obligatorias:

1. El cliente se obtiene siempre del token validado.
2. Un parámetro de URL o JSON nunca puede cambiar el cliente efectivo.
3. Toda consulta incluye internamente el identificador del cliente.
4. Cada endpoint exige un ámbito concreto.
5. Los usuarios móviles se filtran también por empresa y almacén.
6. Los tokens revocados o caducados dejan de funcionar inmediatamente.
7. Los endpoints administrativos quedan denegados por defecto.

Ejemplo conceptual:

```php
$identidad = exigir_instalacion('ventas:escribir');
$idCliente = $identidad['id_cliente'];
```

El endpoint no tomará `id_cliente` ni `carpeta_cliente` del cuerpo para decidir
dónde escribir.

## 8. Núcleo PHP común

Todos los endpoints nuevos deberán cargar un único arranque, por ejemplo:

```text
api/
├── config/
│   └── config.php
├── comun/
│   ├── inicio.php
│   ├── conexion.php
│   ├── autenticacion.php
│   ├── autorizacion.php
│   ├── respuesta.php
│   ├── validacion.php
│   └── auditoria.php
└── public/
    └── api/v1/
        ├── instalaciones/
        ├── auth/
        ├── ventas/
        ├── recuentos/
        └── fotos/
```

La configuración real debe permanecer fuera del directorio público y del
control de versiones. No se introducirán credenciales reales en plantillas.

Responsabilidades del núcleo:

- Conexiones PDO con excepciones y `utf8mb4`.
- Validación del método HTTP y del cuerpo JSON.
- Lectura y validación de `Authorization`.
- Resolución de cliente, instalación, usuario y permisos.
- Respuestas JSON homogéneas.
- Identificador único por petición.
- Auditoría sin almacenar tokens ni contraseñas.
- Límites comunes de tamaño y frecuencia.
- Tratamiento controlado de excepciones.
- Cabeceras de seguridad y CORS cerrado por defecto.

## 9. Contrato común de respuesta

Respuesta correcta:

```json
{
  "ok": true,
  "datos": {},
  "id_peticion": "01J..."
}
```

Respuesta de error:

```json
{
  "ok": false,
  "error": {
    "codigo": "TOKEN_INVALIDO",
    "mensaje": "La credencial no es válida"
  },
  "id_peticion": "01J..."
}
```

Códigos HTTP mínimos:

| Código | Uso |
|---|---|
| `200` | Consulta o modificación correcta. |
| `201` | Recurso creado. |
| `400` | Petición o JSON incorrecto. |
| `401` | Falta autenticación o no es válida. |
| `403` | Identidad válida sin permiso suficiente. |
| `404` | Recurso inexistente dentro del cliente autorizado. |
| `409` | Conflicto de estado o idempotencia. |
| `413` | Cuerpo o fichero demasiado grande. |
| `422` | Datos con formato válido pero no aceptables. |
| `429` | Demasiadas peticiones. |
| `500` | Error interno sin revelar detalles sensibles. |

Las fechas intercambiadas por la API usarán ISO 8601 y UTC. La presentación
en hora local corresponde al cliente.

## 10. Modelo inicial de la BBDD de identidad

Tablas conceptuales propuestas:

| Tabla | Función |
|---|---|
| `api_clientes` | Identidad del cliente o tenant. |
| `api_instalaciones` | Instalaciones de Factuzam vinculadas al cliente. |
| `api_tokens_instalacion` | Hash, ámbitos, caducidad y revocación. |
| `api_usuarios` | Usuarios de aplicaciones web y móviles. |
| `api_sesiones` | Tokens de acceso y renovación de usuarios. |
| `api_dispositivos` | Terminales autorizados y su vinculación. |
| `api_auditoria` | Accesos y operaciones relevantes. |
| `api_intentos_login` | Control de intentos y bloqueos temporales. |

El esquema definitivo se implementará en un SQL idempotente independiente. Al
ser una BBDD propia del servidor PHP, puede mantener `snake_case` como la BBDD
actual de recuentos. No se añadirá este esquema a `factuzam_original.sql`.

## 11. Nuevo servicio de ventas

Ventas será el primer dominio construido directamente sobre el núcleo nuevo.
Servirá como prueba antes de migrar los servicios existentes.

Separación propuesta:

```text
POST /api/v1/ventas/eventos
     Identidad: instalación de Factuzam
     Ámbito: ventas:escribir

GET  /api/v1/ventas
     Identidad: usuario móvil
     Ámbito: ventas:leer
```

Factuzam enviará altas, modificaciones, anulaciones y devoluciones. Cada
evento tendrá un UUID único. Reenviar el mismo UUID no duplicará la venta.

La app consultará la copia preparada para lectura; nunca se conectará a la
MariaDB del cliente ni utilizará el token técnico de Factuzam.

El contrato funcional de ventas deberá concretar en otro documento:

- Documentos incluidos.
- Momento en que una venta se considera confirmada.
- Tratamiento de anulaciones y devoluciones.
- Empresas, almacenes y cajas visibles.
- Nivel de detalle y datos personales permitidos.
- Retención de datos en la nube.
- Latencia aceptable y recuperación tras falta de conexión.

## 12. Cliente HTTP común en Delphi

Se propone una unidad `src/Lib/inLibFactuzamApi.pas` responsable de:

- URL base única.
- Token de instalación.
- Cabeceras comunes.
- Serialización y lectura JSON.
- Tiempo de conexión y respuesta.
- Reintentos seguros.
- Interpretación del contrato de error.
- Identificador de petición en el log.
- Ocultación de credenciales en mensajes y logs.

Parámetros objetivo:

| Parámetro | Función |
|---|---|
| `appApiUrl` | URL base, hasta `/api/v1/`. |
| `appApiReferencia` | Referencia pública de la instalación. |
| `appApiToken` | Token protegido de la instalación. |

Los parámetros anteriores de fotos y recuentos se cargan de forma oculta como
respaldo cuando el conjunto común todavía está vacío. La pantalla muestra un
único juego de URL, credencial y referencia para todos los servicios.

Las unidades de dominio seguirán existiendo:

- `inLibFotosNube` conoce fotos.
- `inLibInventarioNube` conoce recuentos.
- La futura unidad de ventas conoce ventas.
- `inLibFactuzamApi` conoce transporte y autenticación.

## 13. Compatibilidad durante la migración

No se cambiarán simultáneamente servidor y todas las instalaciones.

Estrategia:

1. Publicar `/api/v1/` sin retirar los PHP existentes.
2. Entregar credenciales nuevas por instalación.
3. Hacer que las versiones nuevas de Factuzam prefieran la API v1.
4. Mantener temporalmente el endpoint anterior como alternativa controlada.
5. Registrar qué instalaciones siguen utilizando endpoints antiguos.
6. Comunicar una fecha de retirada cuando el uso sea residual.
7. Revocar las claves maestras después de cerrar la migración.

Los endpoints antiguos no recibirán funcionalidades nuevas salvo correcciones
de seguridad necesarias. La nueva consulta de ventas nacerá únicamente en v1.

## 14. Fases de trabajo

### Fase 0. Confirmar inventario y producción

- Identificar host y ruta real de cada PHP desplegado.
- Confirmar qué variante de fotos está activa.
- Localizar o descartar los PHP de backup referenciados.
- Identificar BBDD, usuarios, carpetas y permisos del hosting.
- Anotar versiones de Factuzam que consumen cada contrato.

### Fase 1. Núcleo común

- Crear estructura `/api/v1/`.
- Crear configuración privada.
- Implementar respuesta, validación, PDO, auditoría y gestión de errores.
- Crear BBDD de identidad mediante script idempotente.
- Añadir pruebas de aislamiento entre dos clientes.

### Fase 2. Alta y credencial de instalación

- Definir el alta inicial mediante código de activación de un solo uso.
- Generar un token distinto para cada instalación.
- Guardar solamente su hash en servidor.
- Implementar rotación y revocación.
- Adaptar el servicio de número de instalación SIF.
- Proteger el token localmente en Windows.

### Fase 3. Ventas como servicio piloto

- Definir el contrato de eventos de ventas.
- Crear cola local idempotente en Factuzam.
- Implementar recepción y consolidación en servidor.
- Crear usuarios y login móvil.
- Implementar consulta filtrada por cliente, empresa y almacén.
- Medir latencia, reintentos y consumo.

### Fase 4. Recuentos

- Migrar primero los endpoints usados por Factuzam.
- Migrar el alta y los tokens de dispositivos.
- Sustituir `X-Carpeta` como selector por el cliente del token.
- Mantener UUID, cursores y comportamiento offline actual.
- Actualizar la app FMX y después retirar la clave de alta global.

### Fase 5. Fotos

- Confirmar y consolidar la variante activa.
- Mover la clave al núcleo común.
- Autorizar lectura y escritura con ámbitos diferentes.
- Derivar la carpeta física desde el cliente autenticado.
- Mantener nombres, hashes, tamaños y ZIP actuales.
- Retirar las claves incrustadas cuando no quede ningún consumidor antiguo.

### Fase 6. Retirada del legado

- Comprobar que no hay accesos a PHP antiguos durante el periodo acordado.
- Desactivar endpoints antiguos de forma reversible.
- Revocar claves globales.
- Eliminar parámetros obsoletos en una versión posterior.
- Actualizar la documentación operativa y de recuperación.

## 15. Pruebas mínimas obligatorias

### Seguridad

- Petición sin token, con token incorrecto, caducado y revocado.
- Token válido sin el ámbito requerido.
- Cliente A intentando consultar o modificar recursos del cliente B.
- Manipulación de `carpeta_cliente`, empresa, almacén e identificadores.
- Intentos repetidos de login y registro de dispositivo.
- Token ausente en logs, excepciones y respuestas.
- Restricción de tamaño y tipo en subida de fotos.
- Comprobación de rutas para impedir salir de la carpeta autorizada.

### Funcionalidad

- Reenvío del mismo evento sin duplicación.
- Recuperación después de perder Internet.
- Cursores de recuentos sin saltos ni duplicados.
- Alta, modificación, anulación y devolución de venta.
- Rotación de token sin pérdida de servicio.
- Compatibilidad simultánea de endpoint antiguo y v1.

### Operación

- Copia y restauración de la BBDD de identidad.
- Revocación urgente de una instalación.
- Identificación de una petición mediante `id_peticion`.
- Alertas por errores repetidos y exceso de autenticaciones fallidas.
- Comprobación de HTTPS y renovación de certificado.

## 16. Criterios de aceptación

La migración podrá considerarse terminada cuando:

1. Cada instalación tenga su propia credencial revocable.
2. Ningún endpoint dependa de una clave global compartida.
3. El cliente efectivo se derive siempre de la identidad autenticada.
4. Fotos, recuentos, instalación y ventas utilicen el núcleo común.
5. Factuzam utilice un único cliente HTTP y una URL base.
6. Los usuarios móviles tengan identidad y permisos propios.
7. Los endpoints antiguos no reciban tráfico y estén desactivados.
8. No existan credenciales reales dentro del repositorio.
9. Existan pruebas automáticas de aislamiento entre clientes.
10. La rotación, revocación, backup y recuperación estén documentados.

## 17. Decisiones pendientes

| Decisión | Propuesta inicial |
|---|---|
| Dominio definitivo | Un único host con `/api/v1/`. |
| Hosting | Mantener PHP 8.x y PDO en el hosting actual durante la migración. |
| BBDD de identidad | Nueva BBDD `factuzam_api`. |
| Formato del token | Token opaco aleatorio; no JWT inicialmente. |
| Alta de instalación | Código de activación de un solo uso. |
| Protección local | DPAPI de Windows. |
| Primer dominio nuevo | Ventas. |
| Primer servicio legado a migrar | Instalación SIF y después recuentos. |
| Identidad móvil | Usuario individual, no token técnico de instalación. |
| Periodo de convivencia | Definir después de inventariar versiones activas. |

## 18. Próximos entregables

1. Inventario confirmado de producción con URLs y versiones consumidoras.
2. Diseño SQL idempotente de la BBDD `factuzam_api`.
3. Contrato técnico del núcleo `/api/v1/`.
4. Diseño funcional y contrato de eventos del servicio de ventas.
5. Prototipo de `inLibFactuzamApi` sin migrar todavía los dominios existentes.
6. Plan de alta y entrega segura de credenciales a instalaciones existentes.

## 19. Reglas del repositorio aplicables

- `factuzam_original.sql` no se modifica.
- Todo cambio de esquema se entregará en un script idempotente separado dentro
  de `DESARROLLOS EN CURSO/`.
- Código, comentarios, mensajes y documentación permanecerán en español.
- Se mantiene UniDAC y `THTTPClient`; no se añaden dependencias sin justificar.
- No se retirará ni renombrará un servicio desplegado sin inventario,
  compatibilidad, fecha de corte y procedimiento de vuelta atrás.
