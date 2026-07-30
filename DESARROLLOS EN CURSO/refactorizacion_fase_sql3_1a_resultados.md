# Resultado SQL-3.1a — lecturas de sesiones de compra

Fecha: 30/07/2026.

## Alcance

Primera sub-tanda de la prioridad 1 de SQL-3. Se han extraído seis
construcciones de lectura que estaban dentro del adaptador mixto
`UniDataComprasSesionesOperaciones`:

1. códigos básicos activos;
2. nombre de familia;
3. duplicado por código de artículo;
4. duplicado por referencia del proveedor;
5. duplicado dentro de la misma sesión;
6. PVP del artículo reutilizado.

Las dos lecturas que ya estaban catalogadas, siguiente línea y cantidades
por talla, se conservan. El repositorio de sesiones registra ahora ocho
definiciones.

## Contrato

`IRepositorioLecturasComprasSesiones` contiene únicamente consultas.
`IRepositorioComprasSesiones` hereda de él y conserva temporalmente las
escrituras para no romper consumidores.

`ResolverCodigoFamilia` no se ha clasificado como lectura: realiza
`SELECT ... FOR UPDATE` y actualiza el contador de la familia.

`inLibComprasSesiones` sigue siendo una fachada sin UniDAC y sin SQL. Las
seis lecturas extraídas se pueden sustituir por un repositorio falso; la
prueba `ContratoLecturasAdmiteRepositorioFalso` lo caracteriza sin BBDD.

## Catálogo y fallback

Las operaciones nuevas usan `pesPerfilLecturaConFallback` y las claves:

- `SQL__RepositorioComprasSesiones__ConsultarCodigosBasicosActivos`;
- `SQL__RepositorioComprasSesiones__ObtenerNombreFamilia`;
- `SQL__RepositorioComprasSesiones__ResolverDuplicadoPorCodigo`;
- `SQL__RepositorioComprasSesiones__ResolverDuplicadoPorReferencia`;
- `SQL__RepositorioComprasSesiones__ResolverDuplicadoIntraSesion`;
- `SQL__RepositorioComprasSesiones__ObtenerPvpArticulo`.

El perfil se valida por parámetros y campos de salida. Si el perfil no es
válido o falla al ejecutarse, se repite la lectura con el SQL base.

## Compatibilidad

La consulta de PVP se ejecuta ahora antes de delegar la edición de la
línea. El adaptador de escritura recibe el valor resuelto y ya no consulta
la BBDD. El orden funcional se conserva:

1. resolver el artículo;
2. resolver el PVP cuando el origen no es otra línea de la sesión;
3. aplicar el resultado al dataset.

## Verificación

- compilación DUnitX Win64 Debug correcta;
- 320 pruebas encontradas y 320 superadas;
- las ocho definiciones del repositorio superan la validación de
  metadatos;
- el registro de aplicación aumenta de 89 a 95 definiciones;
- `git diff --check` sin errores.

## Pendiente de SQL-3.1

Quedan en la siguiente sub-tanda:

- dos lecturas de kits;
- siete lecturas del validador detallado;
- las lecturas internas de materialización y reversión.

Las escrituras que permanecen se detallan en
`inventario_escrituras_sql3_compras_sesiones.md`.
