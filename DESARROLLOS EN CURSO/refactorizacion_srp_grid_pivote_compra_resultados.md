# División SRP de `TGridPivoteCompra`

Fecha: 01/08/2026. Sin commit.

## Resultado

`TGridPivoteCompra` queda como una fachada de coordinación y conserva su API
pública. La implementación se reparte por responsabilidad en estas unidades:

| Responsabilidad | Unidad / clase |
|---|---|
| Coordinación | `inLibGridPivoteCompra` / `TGridPivoteCompra` |
| Presentación y distribución | `inLibGridPivoteCompraPresentacion` / `TPresentacionPivoteCompra` |
| Correspondencia de celdas, líneas y SKU | `inLibPivoteCompraCorrespondencia` / `TCorrespondenciaPivoteCompra` |
| Validación | `inLibPivoteCompraValidacion` / `TValidadorPivoteCompra` |
| Edición y recepción de datos | `inLibGridPivoteCompraEdicion` / `TEdicionPivoteCompra` |

Como apoyo, `inLibGridPivoteCompraTipos` contiene la configuración y los tipos
compartidos, `inLibPivoteCompraEstadoEdicion` encapsula el estado editable y
`inLibPivoteCompraCalculo` reúne cálculos puros de claves, cantidades, estados
de recepción y prefijos SKU.

No se ha cambiado ningún formulario consumidor ni la firma pública de la
fachada. Tampoco se ha modificado el esquema de base de datos ni se ha añadido
SQL literal.

## Medición

| Clase | Líneas | Métodos | Campos |
|---|---:|---:|---:|
| `TGridPivoteCompra`, antes | 2.490 | 48 | 32 |
| `TGridPivoteCompra`, después | **259** | **29** | **5** |
| `TCachePivoteCompra` | 127 | 3 | 20 |
| `TCorrespondenciaPivoteCompra` | 432 | 11 | 3 |
| `TEstadoEdicionPivoteCompra` | 33 | 3 | 2 |
| `TValidadorPivoteCompra` | 126 | 3 | 3 |
| `TPresentacionPivoteCompra` | 705 | 19 | 11 |
| `TEdicionPivoteCompra` | 1.170 | 21 | 9 |

La unidad de fachada baja de 2.635 a 315 líneas físicas. Todas las clases
extraídas quedan dentro de su objetivo; el método más largo del nuevo bloque
tiene 119 líneas. Los valores quedan congelados como trinquetes en
`scripts/comprobar_tamano_clases.ps1`.

## Pruebas y verificaciones

Se añaden seis pruebas DUnitX para los cálculos puros:

- reversibilidad de la clave línea/talla;
- tratamiento de líneas sin talla;
- cuatro estados de recepción;
- pendiente nunca negativo;
- cantidad a recibir limitada al pendiente;
- obtención del prefijo de un SKU con talla.

| Validación | Resultado |
|---|---:|
| Compilación aislada final, Debug/Win32 | 0 errores |
| Compilación aislada final, Debug/Win64 | 0 errores |
| DUnitX final, Debug/Win32 | **541/541**, 0 fugas |
| Matriz previa, Debug/Release y Win32/Win64 | **541/541** en las cuatro combinaciones |
| Dependencias de capas | OK; 0 usos `inLib* -> UniData*` |
| SQL literal en dominio | OK; 0 SQL nuevo en el bloque |
| Trinquete de estilo global | OK |
| Trinquete de tamaño limitado al bloque | OK |

La repetición final del build global está bloqueada por trabajo concurrente
ajeno a este cambio: `inLibAtributosPaleta.pas` presenta declaraciones
desfasadas respecto de `inLibAtributosPaletaIntf.pas` (E2267 y E2010). No se
ha modificado ni revertido ese trabajo. El control global de tamaño también
detecta trinquetes desfasados en otras clases y unidades; las siete clases del
pivote sí pasan con sus límites exactos.

## Prueba funcional pendiente

1. Activar y desactivar el pivote en pedidos y albaranes de compra.
2. Editar una cantidad de talla existente y otra que requiera crear la línea
   SKU real.
3. Expandir un pedido, recibir una fila y recibir todo, tanto parcial como
   totalmente.
4. Cambiar el color de la línea activa y verificar el repintado y la
   correspondencia de SKU.
