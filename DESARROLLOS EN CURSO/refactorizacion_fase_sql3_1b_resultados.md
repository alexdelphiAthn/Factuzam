# Resultado SQL-3.1b — kits y validación de sesiones

Fecha: 30/07/2026.

## Alcance

Segunda sub-tanda de la prioridad 1 de SQL-3. Se han extraído las nueve
lecturas que todavía quedaban en
`UniDataComprasSesionesOperaciones`:

- cabecera del kit y nombres de tallaje;
- detalles y cantidades del kit;
- existencia de líneas;
- duplicados internos sin resolver;
- duplicados externos sin resolver;
- líneas sin código;
- líneas sin descripción;
- matrices sin cantidades;
- matrices sin sistema de tallas.

El adaptador conserva exclusivamente escrituras. Los únicos `SELECT` que
permanecen en su texto forman parte de `INSERT ... SELECT` o de subconsultas
de un `UPDATE`; no son operaciones de lectura independientes.

## Contrato y consumidores

Se han añadido al contrato de lecturas los DTO:

- `TKitProveedorSesion`;
- `TDetalleKitProveedorSesion`;
- `TDetallesKitProveedorSesion`.

El formulario sigue siendo responsable de aplicar las cantidades mediante
el gestor de tallas, pero obtiene los datos a través de
`TServicioComprasSesiones`. De este modo, el flujo de interfaz no conoce
SQL ni UniDAC y el repositorio puede sustituirse por un falso.

La validación detallada se ejecuta ahora en el repositorio de lecturas.
Cada regla conserva su operación propia para que un cambio de perfil no
pueda alterar silenciosamente las demás validaciones.

## Catálogo

El repositorio de sesiones pasa de 8 a 17 lecturas catalogadas. Las nuevas
claves son:

- `SQL__RepositorioComprasSesiones__ConsultarKitProveedor`;
- `SQL__RepositorioComprasSesiones__ConsultarDetallesKitProveedor`;
- `SQL__RepositorioComprasSesiones__ValidarSesionConLineas`;
- `SQL__RepositorioComprasSesiones__ValidarDuplicadosInternos`;
- `SQL__RepositorioComprasSesiones__ValidarDuplicadosExternos`;
- `SQL__RepositorioComprasSesiones__ValidarLineasSinCodigo`;
- `SQL__RepositorioComprasSesiones__ValidarLineasSinDescripcion`;
- `SQL__RepositorioComprasSesiones__ValidarMatricesSinCantidades`;
- `SQL__RepositorioComprasSesiones__ValidarMatricesSinTallaje`.

Todas usan `pesPerfilLecturaConFallback`. Los resultados parciales de una
consulta de perfil que falle no se mezclan con el reintento base: cada
intento acumula sus incidencias en una lista temporal y solo se publica si
termina correctamente.

## Verificación

- compilación DUnitX Win64 Debug correcta;
- 321 pruebas encontradas y 321 superadas;
- las 17 definiciones del repositorio superan la validación de parámetros,
  campos y política;
- el registro de aplicación contiene 104 definiciones;
- el guarda de SQL y transacciones informa de 0 valores externos
  concatenados.

La compilación del ejecutable Win64 no llega a las unidades modificadas
porque la instalación local no contiene `frxClass` de FastReport. Es un
bloqueo de dependencias del proyecto principal, no un error detectado en
esta tanda.

## Pendiente de la prioridad 1

Las fachadas `inLibComprasSesiones` e
`inLibComprasSesionesMaterializar` no contienen SQL. Queda extraer y
catalogar las lecturas internas de los adaptadores especializados de
materialización y reversión.
