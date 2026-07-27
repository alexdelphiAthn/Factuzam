# Fase 6L — básicos de color comunes por artículo (resultados)

Fecha: 27/07/2026. Duodécimo fascículo de D1 terminado. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| Tres métodos de formulario | 150 | 21 | -129 |
| Ampliación de la librería común | 0 | 62 | +62 |
| Total productivo del alcance | 150 | 83 | **-67** |

El código productivo del alcance baja un 45 %.

El contador de compilación principal pasa de 307.802 a 307.725 líneas.
Su descenso de 77 líneas no se usa como métrica porque depende de las
unidades que Delphi decide compilar.

## Implementación

`inLibAtributosPaleta` incorpora:

- `SqlBasicosArticulo`, que conserva las relaciones entre SKU, valores y
  atributos básicos;
- `ObtenerBasicosArticulo`, que ejecuta la consulta parametrizada y
  devuelve los códigos básicos ordenados;
- filtros de activos para SKU, valor y atributo básico;
- compatibilidad con valores vinculados por ID o por código heredado.

Albaranes, facturas y pedidos de compra conservan adaptadores de siete
líneas. Cada uno sigue proporcionando explícitamente:

- `ConexionPrincipal`;
- el código de artículo;
- `ID_VA_COLOR`;
- su propio campo `FBasicosColor`.

No se ha incluido devoluciones porque no tenía este método ni el mismo
flujo de selección de color.

## Pruebas automáticas

Se añade `PruebasAtributosPaleta` para comprobar:

1. tablas, relaciones y parámetros de la consulta;
2. filtros de registros activos;
3. orden de la paleta;
4. que un artículo vacío no abre ninguna consulta.

La batería DUnitX pasa de 45 a 47 casos:

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 47/47 | 0 | 0 |
| Debug / Win32 | 0 errores | 47/47 | 0 | 0 |
| Release / Win64 | 0 errores | 47/47 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.725
líneas en 10,89 segundos.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6L no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- fuentes modificadas en UTF-8 con BOM y CRLF;
- líneas nuevas dentro del máximo de 80 columnas;
- `git diff --check` de los archivos de la fase sin errores;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

En albaranes, facturas y pedidos de compra:

1. seleccionar un artículo sin SKU o colores y comprobar la lista vacía;
2. seleccionar un artículo con varios colores básicos;
3. comprobar orden, ausencia de duplicados y apertura del selector;
4. verificar que SKU, valores y básicos inactivos quedan excluidos;
5. cambiar a un artículo vacío y confirmar que se limpia la lista anterior;
6. repetir el mismo artículo en los tres documentos y comparar resultados.

El siguiente fascículo previsto es 6M: `CrearTablaPrincipal`, de riesgo
alto por construir datasets y determinar campos visibles.
