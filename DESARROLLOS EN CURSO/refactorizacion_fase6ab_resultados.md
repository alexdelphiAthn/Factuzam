# Fase 6AB — datasets y claves de `inLibtb`

Fecha: 28/07/2026. D3.1, primer fascículo de nueve. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `inLibtb` | 1.523 | 1.234 | **-289** |
| `inLibDatasets` | 0 | 399 | +399 |
| Núcleo extraído | 1.523 | 1.633 | **+110** |
| Tres consumidores migrados | 3.551 | 3.559 | +8 |
| Total productivo del alcance | 5.074 | 5.192 | **+118** |

La fachada baja un 19,0 %. El alcance productivo completo crece un
2,3 % por las firmas públicas, las delegaciones compatibles y la
separación de dependencias. Las 262 líneas de `PruebasDatasets.pas`
quedan excluidas.

Al iniciar la tanda había 50 dependencias directas de producción sobre
`inLibtb`, incluida la propia fachada. Quedan 48: 47 consumidores y la
fachada. Este recuento se corrigió en D3.4 para incluir el `inlibtb` en
minúsculas de `inMtoLogon`.

## Implementación

La nueva unidad `inLibDatasets` concentra ocho operaciones:

- conversión de claves simples y compuestas;
- extracción de la tabla principal de una sentencia SQL;
- obtención de la clave primaria mediante `KeyFields`,
  `ProviderFlags` o `information_schema`;
- grabación y cancelación de datasets de un módulo de datos;
- detección de datasets en edición o inserción;
- validación de periodos que no deben solaparse.

`inLibtb` conserva las ocho firmas anteriores y delega en la nueva
unidad, por lo que los consumidores existentes siguen siendo
compatibles. La firma especializada de `ExistePeriodoUnico` acepta
`TDataSet`; la fachada conserva `TUniQuery`.

La interfaz de `inLibtb` deja de exponer las dependencias de
`Datasnap.Provider`, `Datasnap.DBClient`, `System.DateUtils` y Midas.
`MidasLib` queda en la implementación de `inLibDatasets`, donde se
utiliza.

Se migran directamente:

- `TfrmMtoGen`, para grabar, cancelar y detectar datasets abiertos;
- `inLibDevExp`, para claves primarias y valores de clave;
- `inLibDir`, eliminando una dependencia que no utilizaba.

## Pruebas automáticas

`PruebasDatasets.pas` añade ocho pruebas DUnitX sin BBDD:

1. compatibilidad de una clave simple con la fachada;
2. ida y vuelta de una clave compuesta;
3. relleno con `Null` de una clave compuesta incompleta;
4. extracción de tabla ignorando subconsultas y comillas invertidas;
5. detección de clave primaria mediante `ProviderFlags`;
6. grabación, cancelación y detección del estado de datasets;
7. aceptación de un único periodo existente;
8. detección de un solapamiento.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 117/117 | 0 | 0 |
| Debug / Win32 | 0 errores | 117/117 | 0 | 0 |
| Release / Win64 | 0 errores | 117/117 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de los fuentes
modificados. La aplicación principal Release/Win64 se reconstruyó con
Delphi 37 sin errores: 310.877 líneas y 10,75 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. D3.1 no
modifica esa unidad.

Comprobaciones adicionales:

- dependencias de capa;
- fuentes Pascal del alcance en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- ningún `Exit` o `Continue` nuevo;
- `git diff --check`;
- `factuzam_original.sql` intacto.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Abrir mantenimientos con claves simples y compuestas.
2. Navegar y restaurar la fila seleccionada tras un refresco.
3. Editar y cerrar un mantenimiento confirmando la grabación.
4. Cancelar una edición y comprobar la restauración del registro.
5. Verificar el fallback de clave primaria contra
   `information_schema`.
6. Validar periodos abiertos, cerrados, contiguos y solapados.
7. Probar los flujos de `inLibDevExp` que conservan la selección.

D3 queda abierto: **1 de 9 fascículos**. Los ocho restantes son:

1. series, contadores y valores por defecto;
2. recálculo genérico de líneas de factura;
3. cadenas, perfiles y símbolos prohibidos;
4. construcción de conexiones heredadas;
5. cifrado AES;
6. búsquedas y filtros;
7. INI, ficheros y rutas;
8. NIF, CCC e IBAN.

El siguiente fascículo es D3.2: series, contadores y valores por defecto.
