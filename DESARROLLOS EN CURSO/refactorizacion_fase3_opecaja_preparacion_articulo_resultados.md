# Fase 3 — `inMtoCajaOpe`: preparación del artículo de la línea

Fecha: 01/08/2026. Sin commit.

## Resultado

Se ha extraído de `TfrmMtoOpeCaja.RellenarDatosArticuloEnDataset` la
responsabilidad de resolver una entrada manual o de escáner y preparar los
campos de la línea de venta.

La lógica vive ahora en `PrepararArticuloLineaVenta`, dentro de
`inLibCajaVentaOperacion`. Trabaja con `TDataSet` y los contratos
`IArticulosValidador` e `IArticulosResolver`; no conoce formularios,
DevExpress, UniDAC ni SQL. Las reacciones visuales de consulta de stock y
recálculo de precio se inyectan mediante callbacks tipados.

El formulario conserva únicamente la composición de los resolutores, la
delegación y el recálculo final del grid.

## Medición

| Métrica | Antes | Después |
|---|---:|---:|
| `TfrmMtoOpeCaja` — líneas | 3.975 | **3.894** |
| `TfrmMtoOpeCaja` — métodos | 104 | **104** |
| `RellenarDatosArticuloEnDataset` — líneas | 117 | **36** |

El tope individual y el máximo global de
`scripts/comprobar_tamano_clases.ps1` bajan a 3.894 líneas.

## Pruebas

Se añaden seis casos DUnitX a `PruebasCajaVentaOperacion`:

- entrada manual mediante la resolución general;
- entrada de escáner limitada a códigos de barras;
- SKU resuelto, escritura de campos y callbacks de stock/precio;
- artículo padre pendiente de SKU, IVA y descuento base;
- artículo sin SKU vendible y conservación del motivo de rechazo;
- carga de depósitos sin consulta de stock adicional.

Validaciones realizadas:

| Validación | Resultado |
|---|---:|
| Build `FactuzamTests`, Debug/Win64 | 0 errores |
| Batería DUnitX | **541/541** |
| Build `fzam.dproj`, Release/Win64 | 0 errores |
| Compilación aislada final de `inMtoCajaOpe` | 0 errores |
| Dependencias de capas | OK |
| Trinquete de estilo | OK |

La repetición final del build global quedó bloqueada por trabajo concurrente
ajeno a este fascículo: `inMtoStockConsulta.pas` llama a
`CrearLineaDocumentoTrabajo` con una firma desfasada (E2010 en las líneas
1028-1033). No se ha modificado ni revertido ese trabajo.

## Prueba funcional pendiente

1. Introducir un artículo simple manualmente y confirmar precio y stock.
2. Escanear un código EAN con SKU completo y confirmar el alta de la línea.
3. Introducir un artículo con talla/color y confirmar IVA, descuento y
   selección posterior del SKU.
4. Cargar depósitos de cliente y comprobar que no se duplica la consulta de
   stock.
