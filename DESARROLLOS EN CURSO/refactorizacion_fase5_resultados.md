# Fase 5 — red de seguridad DUnitX (resultados)

Fecha: 27/07/2026. Implementación terminada. Sin commit.

## Resultado

Se ha creado el proyecto de consola
[`FactuzamTests.dproj`](../tests/FactuzamTests.dproj), ejecutable tanto
desde el IDE de Delphi como desde la línea de órdenes. Usa el DUnitX incluido
con Delphi 37, sin añadir dependencias al repositorio ni modificar lógica de
producción.

El proyecto contiene dos fixtures y 16 casos de prueba:

- `TPruebasImpuestosComun`, con 9 casos para los accesos tolerantes a campos,
  detección y escritura de cambios, tipos de IVA, selección de porcentajes,
  conversiones con IVA decimal, extracción del sufijo fiscal y guardas de las
  lecturas que requieren conexión.
- `TPruebasTotalesDocumentos`, con 7 casos sobre datasets en memoria para
  agrupación fiscal de ventas, descuentos y retención de compras, documentos
  exentos, restauración de filtros y cálculo de prendas.

Los datasets se construyen en cada prueba y no necesitan interfaz, ficheros
externos ni una base de datos activa. `MidasLib` queda enlazado estáticamente
para que el ejecutable tampoco dependa de `midas.dll`.

## Verificación realizada

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 16/16 | 0 | 0 |
| Debug / Win32 | 0 errores | 16/16 | 0 | 0 |
| Release / Win64 | 0 errores | 16/16 | 0 | 0 |

DUnitX informó en las tres ejecuciones:

```text
Tests Found   : 16
Tests Ignored : 0
Tests Passed  : 16
Tests Leaked  : 0
Tests Failed  : 0
Tests Errored : 0
```

El `.gitignore` excluye `tests/bin/`, `tests/dcu/` y el recurso de proyecto
generado. Los archivos `.dpr`, `.dproj` y `.pas` no están ignorados.

Las nuevas fuentes Pascal están en UTF-8 con BOM, usan CRLF y no superan las
80 columnas. `factuzam_original.sql` no se ha modificado.

## Ejecución desde línea de órdenes

En una consola con las variables de Delphi cargadas:

```bat
msbuild tests\FactuzamTests.dproj /t:Build /p:Config=Debug /p:Platform=Win64
tests\bin\Win64\Debug\FactuzamTests.exe
```

Para Win32 basta con sustituir `Win64` por `Win32`. Desde el IDE se puede abrir
directamente `tests\FactuzamTests.dproj` y ejecutar el proyecto de consola.

## Alcance pendiente

Los caminos que consultan porcentajes reales mediante `TUniConnection` se
prueban aquí únicamente en sus guardas sin conexión. Su integración con datos
reales sigue cubierta por las baterías Python existentes, que se mantienen
separadas porque validan SQL y contratos de procedimientos almacenados.

A partir de la fase 6, cada colaborador extraído de una clase grande deberá
añadir sus casos a este proyecto antes de retirar el código anterior.
