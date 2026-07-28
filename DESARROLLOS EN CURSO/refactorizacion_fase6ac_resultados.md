# Fase 6AC — series, contadores y valores automáticos

Fecha: 28/07/2026. D3.2, segundo fascículo de nueve. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `inLibtb` | 1.234 | 1.069 | **-165** |
| `inLibValoresAutomaticos` | 0 | 270 | +270 |
| Núcleo extraído | 1.234 | 1.339 | **+105** |
| 34 consumidores migrados | 53.174 | 53.186 | +12 |
| Total productivo del alcance | 54.408 | 54.525 | **+117** |

La fachada baja un 13,4 %. El alcance productivo completo crece un
0,2 % por la nueva API, las delegaciones compatibles y el helper
comprobable de asignación. Las 179 líneas de
`PruebasValoresAutomaticos.pas` quedan excluidas.

Las dependencias directas de producción sobre `inLibtb`, incluida la
fachada, bajan de 48 a 17 en este fascículo. Desde el inicio de D3 han
bajado de 50 a 17. El recuento se corrigió en D3.4 para incluir el
`inlibtb` en minúsculas de `inMtoLogon`.

Balance acumulado de D3:

- `inLibtb`: 1.523 a 1.069 líneas, **-454 (-29,8 %)**;
- unidades especializadas: 669 líneas;
- núcleo completo: 1.523 a 1.738 líneas, **+215**;
- alcance productivo acumulado: **+235 líneas**.

## Implementación

La nueva unidad `inLibValoresAutomaticos` concentra:

- serie propia de un almacén;
- serie por defecto, con fallback a la serie genérica;
- carga de series vigentes de una empresa;
- obtención transaccional del siguiente contador;
- consulta y aplicación de valores configurados por defecto;
- asignación comprobable de valores `INTEGER`, `FLOAT` y texto.

Se conservan la prioridad de la serie del almacén, la vigencia por
fechas, el filtro que impide tomar la serie de otro almacén y el
procedimiento almacenado `PRC_GET_NEXT_CONT`.

`inLibtb` conserva sus seis firmas anteriores como fachada. La API
especializada usa `ObtenerValorPorDefecto`; la fachada mantiene el
nombre heredado `GetDefaultValue`.

Se han revisado y migrado los 34 consumidores reales del bloque:

- ventas;
- compras;
- inventarios;
- caja;
- modales y librerías de materialización y movimientos.

En 31 consumidores se sustituye completamente `inLibtb`. En
`UniDataArticulos`, `UniDataEmpresas` y `UniDataIvasGrupos` se conservan
ambas unidades porque todavía usan validación de periodos o perfiles,
responsabilidades previstas para D3.3.

`inLibMsg` deja de formar parte de la interfaz de `inLibtb`; permanece
solo en las implementaciones que necesitan sus mensajes.

## Pruebas automáticas

`PruebasValoresAutomaticos.pas` añade seis pruebas DUnitX sin BBDD:

1. una serie propia sin datos no abre una consulta;
2. una serie por defecto sin datos no abre una consulta;
3. la carga sin empresa o tipo limpia la lista;
4. los valores de texto, entero y decimal se convierten;
5. un campo inexistente se ignora;
6. un número inválido usa el fallback cero.

Las tres primeras comprueban también las delegaciones compatibles de
`inLibtb`.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 123/123 | 0 | 0 |
| Debug / Win32 | 0 errores | 123/123 | 0 | 0 |
| Release / Win64 | 0 errores | 123/123 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de los fuentes
modificados. La aplicación principal Release/Win64 se reconstruyó con
Delphi 37 sin errores: 310.997 líneas y 10,78 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. D3.2 no
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

1. Proponer series en ventas, compras e inventarios.
2. Comprobar la serie propia del almacén y el fallback genérico.
3. Confirmar que nunca se toma la serie de otro almacén.
4. Verificar series vigentes, caducadas y futuras.
5. Revisar los combos ordenados y sin duplicados.
6. Generar contadores de documentos, movimientos y entidades.
7. Confirmar el usuario de modificación del contador.
8. Aplicar valores por defecto en artículos, clientes y empresas.
9. Repetir en facturas y operaciones de caja.
10. Probar valores de texto, enteros, decimales y campos inexistentes.

D3 queda abierto: **2 de 9 fascículos**. El siguiente es D3.3:
cadenas, perfiles y símbolos prohibidos.
