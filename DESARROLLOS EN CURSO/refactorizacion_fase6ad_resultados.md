# Fase 6AD — cadenas, perfiles y símbolos prohibidos

Fecha: 28/07/2026. D3.3, tercer fascículo de nueve. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| `inLibtb` | 1.069 | 1.005 | **-64** |
| `inLibCadenas` | 0 | 145 | +145 |
| Núcleo extraído | 1.069 | 1.150 | **+81** |
| Cinco consumidores migrados | 2.686 | 2.687 | +1 |
| Total productivo del alcance | 3.755 | 3.837 | **+82** |

La fachada baja un 6,0 %. El alcance productivo completo crece un
2,2 % por la nueva API y las delegaciones compatibles. Las 166 líneas
de `PruebasCadenas.pas` quedan excluidas.

Las dependencias directas de producción sobre `inLibtb`, incluida la
fachada, bajan de 17 a 12. Se mantiene deliberadamente el texto
`inLibtb` como clave del perfil histórico de símbolos; no es una
dependencia de unidad. El recuento se corrigió en D3.4 para incluir el
`inlibtb` en minúsculas de `inMtoLogon`.

Balance acumulado de D3:

- `inLibtb`: 1.523 a 1.005 líneas, **-518 (-34,0 %)**;
- unidades especializadas: 814 líneas;
- núcleo completo: 1.523 a 1.819 líneas, **+296**;
- alcance productivo acumulado: **+317 líneas**;
- dependencias directas de `inLibtb`: 50 a 12.

## Implementación

La nueva unidad `inLibCadenas` concentra:

- detección de la primera coincidencia entre dos conjuntos de
  caracteres;
- validación de símbolos prohibidos;
- recuento ANSI de subcadenas sin solapamiento;
- separación ANSI con separadores de varios caracteres.

`inLibtb` conserva las cuatro firmas anteriores y el tipo público
`TStringArray` como alias compatible de `TArrayCadenas`.

La lectura del perfil mantiene exactamente las claves existentes:

- clave: `inLibtb`;
- subclave: `oSimbolosProhibidos`.

Así, los perfiles ya guardados siguen aplicándose aunque la
implementación cambie de unidad.

Se migran los cinco consumidores reales:

- artículos;
- empresas;
- IVA;
- grupos de IVA;
- usuarios.

Los tres primeros todavía usaban `inLibtb` para validar periodos. Pasan
también a `inLibDatasets`, ya extraída en D3.1, y los cinco eliminan por
completo la dependencia de la fachada.

## Pruebas automáticas

`PruebasCadenas.pas` añade seis pruebas DUnitX sin BBDD:

1. se devuelve la primera coincidencia según el orden de la cadena;
2. sin perfil se usa el conjunto de símbolos predeterminado;
3. un perfil sustituye el conjunto predeterminado;
4. las ocurrencias solapadas no se cuentan dos veces;
5. se admite un separador múltiple y una parte final vacía;
6. sin separador se devuelve la cadena completa.

También se comprueban las cuatro delegaciones de `inLibtb` y la
compatibilidad de `TStringArray`.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 129/129 | 0 | 0 |
| Debug / Win32 | 0 errores | 129/129 | 0 | 0 |
| Release / Win64 | 0 errores | 129/129 | 0 | 0 |

Los tres ejecutables se reconstruyeron después de los fuentes
modificados.

La aplicación abierta bloqueaba su ejecutable habitual. Sin cerrarla,
se reconstruyó Release/Win64 con Delphi 37 en
`build/validacion_d33/Win64/Release`: 0 errores, 311.082 líneas y
10,97 segundos.

En las compilaciones Debug de DUnitX aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. D3.3 no
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

1. Crear o editar un artículo con símbolos permitidos y prohibidos.
2. Repetir en empresas, IVA, grupos de IVA y usuarios.
3. Configurar un conjunto personalizado en
   `inLibtb/oSimbolosProhibidos`.
4. Confirmar que el perfil sustituye, y no acumula, los símbolos
   predeterminados.
5. Verificar que artículos, empresas e IVA mantienen la validación de
   periodos.
6. Repetir con un usuario sin perfil específico.

D3 queda abierto: **3 de 9 fascículos**. El siguiente es D3.4:
construcción de conexiones heredadas.
