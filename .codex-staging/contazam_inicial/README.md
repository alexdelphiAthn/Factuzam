# Contazam

Aplicación Delphi VCL para llevar una contabilidad básica multiempresa,
separada de Factuzam y preparada para importar sus facturas sin duplicados.

## Funcionalidad inicial

- Selector de empresa y ejercicio activo.
- Plan contable jerárquico con subcuentas de hasta 15 dígitos.
- Modelo inicial PYMES ampliable sin sobrescribir cuentas propias.
- Libro diario con entrada manual de apuntes Debe/Haber.
- Contrapartidas sugeridas por reglas y uso histórico de cada empresa.
- Validación de cuadre antes de cerrar un asiento.
- Libro mayor con saldo acumulado por cuenta.
- Contadores por empresa, ejercicio, documento y serie.
- Contadores `VARCHAR(30)` que conservan ceros a la izquierda.
- Identificadores obtenidos de `cza_contadores`, sin `AUTO_INCREMENT`.
- Importación idempotente de facturas emitidas desde Factuzam.
- Archivo documental PDF dentro de la BBDD, con SHA-256.
- Bloqueo del cierre si falta el PDF de una referencia indicada.
- Listados de balance, diario, mayor, borradores y archivo documental.
- Exportación directa a `.xlsx` sin depender de Excel instalado.
- Usuarios y grupos con permisos por recurso, acción y alcance.
- Alcance `GLOBAL` o limitado a una empresa concreta.
- Auditoría de consultas y exportaciones con usuario y grupo autorizador.
- Log local por ejecución con niveles de información, aviso y error.
- Captura global de excepciones con detalle copiable y acceso al archivo.
- Rotación de logs antiguos en ZIP, sin envío de datos ni correo electrónico.
- Rejillas Developer Express con búsqueda global, filtros por columna y
  `BestFit` automático seguro que no recorre ni desplaza los registros.

## Bases de datos

- `alexcontazam`: contabilidad personal.
- `contazam`: desarrollo y pruebas.
- Factuzam: solo origen de lectura para importar documentos.

Las tablas usan el prefijo `cza_`, lo que permite alojarlas junto a tablas
`fza_` en el futuro sin colisiones de nombres.

## Puesta en marcha

1. Ejecuta `sql/001_alexcontazam.sql` con un usuario MariaDB que pueda crear
   bases de datos. El script es idempotente.
2. Para preparar también `contazam`, ejecuta
   `scripts/instalar_bases.ps1`; solicita la contraseña sin guardarla.
3. Copia `contazam.ini.example` como
   `%LOCALAPPDATA%\Contazam\contazam.ini`. Esa es la ubicación única de la
   configuración, con independencia de la carpeta del ejecutable.
4. Configura servidor, puerto y usuario. La contraseña puede estar en la
   variable `CONTAZAM_DB_PASSWORD` para no escribirla en disco.
   `Aplicacion/Usuario` identifica al usuario funcional; si está vacío se usa
   el usuario de Windows.
5. Abre `contazam.dproj` con Delphi 13 y compila para Win32.

Los logs se escriben en `%LOCALAPPDATA%\Contazam\log`. Cada ejecución crea
un archivo independiente y los más antiguos se comprimen bajo
`log\archive\año\mes`. La gestión de errores es completamente local: no
incluye correo, SMTP, HTTP ni ningún envío automático.

Cada empresa permite configurar su base de Factuzam y el código de empresa
equivalente. Los PDF se guardan como `LONGBLOB`; una copia SQL puede
representarlos como Base64 o hexadecimal sin alterar el documento restaurado.

## Verificación

- Compilación: `MSBuild contazam.dproj /t:Build /p:Config=Debug`.
- Unitarias: compila y ejecuta `tests/ContazamTests.dpr`.
- Log local: `tests/PruebaIntegracionLogLocal.dpr` escribe un registro real
  bajo `%LOCALAPPDATA%\Contazam\log` y verifica la ruta obtenida.
- Integración BBDD/PDF: `tests/PruebaIntegracionArchivoDocumental.dpr` usa
  exclusivamente la base `contazam` y elimina su documento temporal.
- Integración de listados: `tests/PruebaIntegracionListados.dpr` abre las cinco
  consultas contra `contazam`.
- Integración de seguridad: `tests/PruebaIntegracionSeguridad.dpr` prueba los
  alcances global y de empresa, la denegación cruzada y la auditoría.
- Esquema: ejecuta `sql/002_verificar_alexcontazam.sql`.

Los recursos y acciones configurables están descritos en
`docs/PERMISOS.md`. El primer usuario que abre una instalación sin usuarios se
crea como administrador global para evitar dejar la aplicación bloqueada.

## Aviso contable

El plan incluido es una base operativa inspirada en el PGC de PYMES. Los
asientos importados se crean como borradores. Antes de usar la aplicación con
datos reales conviene que una persona profesional revise el plan, los mapeos,
los impuestos y los criterios contables de la sociedad.
