# Arquitectura de Contazam

Contazam es una aplicación independiente de Factuzam. Reutiliza sus criterios
de estilo y su pila Delphi VCL, UniDAC y MariaDB, pero mantiene sus fuentes,
configuración y bases de datos dentro del proyecto Contazam.

## Capas

- `src/Core`: formulario base y composición visual principal.
- `src/Forms`: coordinación de cada caso de uso y controles VCL.
- `src/DataModules`: SQL, transacciones, contadores e importaciones.
- `src/Lib`: contratos, tipos y reglas puras de dominio.
- `sql`: esquema idempotente y consultas de verificación.
- `tests`: pruebas unitarias e integraciones aisladas en `contazam`.

## Separación multiempresa

Empresa y ejercicio forman parte de las claves lógicas de cuentas, asientos,
reglas, mapeos y documentos. El selector principal pasa un contexto inmutable
a cada pantalla al abrirla. Cambiar el selector no altera pantallas ya abiertas.

Los identificadores técnicos deben ser únicos entre empresas. Por eso los
tipos `ID_ASIENTO`, `ID_APUNTE`, `ID_IMPORTACION` e `ID_DOCUMENTO` usan el
contexto reservado `GLOBAL/0` en `cza_contadores`. La numeración visible
`ASIENTO` continúa separada por empresa y ejercicio.

## Seguridad y alcance

La raíz de composición crea un servicio de seguridad y lo inyecta en todos
los formularios. Los usuarios pertenecen a uno o varios grupos. Cada permiso
es una concesión sobre un recurso y una acción, con alcance `GLOBAL` o
`EMPRESA`. La gestión de usuarios y permisos exige autorización global para
impedir que un administrador de una sola empresa amplíe su propio alcance.

Las consultas y exportaciones de listados registran usuario, grupo que otorgó
el permiso, alcance efectivo, empresa, ejercicio, fechas, cuenta, número de
filas y nombre del archivo. `ID_AUDITORIA_LISTADO` se obtiene de
`cza_contadores` en el contexto `GLOBAL/0`.

## Listados, Excel y FastReport

Los listados son consultas de solo lectura, parametrizadas por empresa,
ejercicio, fechas y prefijo de cuenta. La capa visual autoriza por separado
`CONSULTAR`, `EXPORTAR` y `MODIFICAR`. El exportador genera un contenedor OOXML
`.xlsx` con cabeceras, filtro, filas congeladas y formato numérico. La vista
previa usa Developer Express y no automatización COM.

FastReport genera el formato inicial, muestra su diálogo de vista previa y
permite editarlo. Cada formato derivado se guarda como `LONGBLOB` en
`cza_listados_derivados`; cada modificación crea además una fila inmutable en
`cza_listados_derivados_versiones`. El acceso puede limitarse a usuario, grupo,
empresa o toda la instalación. Los identificadores se obtienen de
`cza_contadores`, sin `AUTO_INCREMENT`.

Las etiquetas visibles de las consultas se resuelven mediante
`cza_literales`. La clave estable es el recurso y el nombre técnico del campo;
el texto se obtiene para el idioma activo, con retorno seguro a `es-ES`.

## Perfiles de mantenimientos

Los mantenimientos heredan las pestañas Lista/Ficha. El perfil de cada usuario,
empresa y clase de formulario conserva posición, tamaño, pestaña activa y, por
columna, nombre visible, orden, visibilidad y ancho. `Alt+F12` lo graba y
`Ctrl+F12` lo elimina para recuperar el diseño predeterminado.

## Archivo documental

El PDF se almacena como `LONGBLOB` en `cza_documentos`. La referencia es única
por empresa y ejercicio. Se guardan nombre, MIME, tamaño y SHA-256. Al cerrar
un asiento, toda referencia de `DOCUMENTO_ASILIN` debe existir en el archivo.

## Importación desde Factuzam

Cada empresa Contazam declara la base y el código de empresa de Factuzam que
le corresponden. La importación solo lee `fza_facturas`, registra su clave de
origen para ser idempotente y crea un asiento en borrador. Nunca escribe en
Factuzam ni cierra el asiento automáticamente.
