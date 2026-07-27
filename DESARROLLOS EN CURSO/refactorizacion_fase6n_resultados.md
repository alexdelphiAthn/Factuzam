# Fase 6N — persistencia común de cabeceras (resultados)

Fecha: 27/07/2026. Decimocuarto fascículo de D1 terminado. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Concepto productivo | Antes | Después | Balance |
|---|---:|---:|---:|
| Persistencia en pedidos y albaranes de venta | 178 | 61 | -117 |
| Librería común de validación documental | 291 | 364 | +73 |
| Núcleo productivo medido | 469 | 425 | **-44** |
| Integración en clases y `uses` | 0 | 3 | +3 |
| Total productivo de 6N | 469 | 428 | **-41** |

El código productivo del alcance baja un 9 %. La prueba DUnitX añadida no
se incluye en estas cifras. La librería nueva no es una duplicación:
`inLibValidacionTallasCompra` se ha renombrado y generalizado como
`inLibValidacionDocumento`.

## Implementación

La unidad común expone ahora un único `TConfiguracionDocumento`, con
alias específicos para persistencia general y tallas de compra. Esto
evita copiar campo a campo entre dos contratos equivalentes.

`AsegurarCabeceraPersistidaDocumento` centraliza:

- validación de una cabecera activa;
- publicación de altas o ediciones antes de trabajar con líneas;
- sincronización de serie y número en la línea activa;
- reapertura del conjunto de líneas tras publicar la cabecera;
- cancelación condicionada de una línea vacía;
- recreación opcional de la línea vacía después de reabrir.

Las diferencias funcionales siguen declaradas como políticas:

- compras solo cancela la línea vacía cuando todavía no hay número;
- compras inicializa el indicador de pivote horizontal a `N`;
- ventas recrea la línea vacía que se cancela al publicar;
- pedidos usa `CODIGOPRODPS_PEDLIN` como producto alternativo;
- pedidos conserva la validación de cliente mediante un callback del
  formulario, incluido el foco y los mensajes existentes;
- albaranes usa `CODIGO_UNIDAD_ALBLIN` y no valida cliente aquí.

Los cuatro documentos de compra mantienen la validación horizontal
existente mediante el adaptador `AsegurarCabeceraPersistidaCompra`.

## Pruebas automáticas

Se añade una prueba sin BBDD que fija la política de ventas: una línea
vacía se cancela para publicar la cabecera y se recrea después, usando
además un campo de producto alternativo al convencional.

| Configuración | Compilación | Pruebas | Fugas | Salida |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 48/48 | 0 | 0 |
| Debug / Win32 | 0 errores | 48/48 | 0 | 0 |
| Release / Win64 | 0 errores | 48/48 | 0 | 0 |

La aplicación principal Release/Win64 compila con 0 errores: 307.842
líneas en 21,84 segundos.

Una repetición posterior sobre el directorio compartido quedó bloqueada
por el E2004 ajeno de `inLibMsg.pas`: el cambio concurrente de literales
declaró dos veces `SErrorArticuloSinSkusActivos`. La compilación correcta
anterior ya incluía todo 6N.

Al compilar DUnitX en Debug aparece el aviso previo H2077 de
`inLibLog.pas`: el valor asignado a `bSQLFinal` no se usa. 6N no modifica
esa unidad.

Comprobaciones adicionales:

- dependencias de capa: `OK`;
- líneas nuevas dentro del máximo de 80 columnas;
- unidad común y prueba nueva en UTF-8 con BOM y CRLF;
- `git diff --check` sin errores propios de contenido;
- `factuzam_original.sql` sin cambios.

## Plan de comprobación funcional

Estado actual: **pendiente de ejecución manual con BBDD**.

1. Crear un pedido sin cliente y confirmar el aviso y el foco en cliente.
2. Crear un pedido con cliente válido, entrar en líneas y comprobar que
   la cabecera obtiene número sin perder la línea vacía.
3. Editar un pedido existente, añadir una línea y verificar serie y número.
4. Repetir alta, edición y primera línea en un albarán de venta.
5. En los cuatro documentos de compra, activar tallas horizontales y
   comprobar que la publicación previa y el pivote siguen funcionando.
6. Guardar una línea real en cada documento y volver a abrirlo.

