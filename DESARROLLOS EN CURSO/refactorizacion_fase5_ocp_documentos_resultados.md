# Fase 5 — OCP: una sola familia de documentos

Fecha: 31/07/2026

## Resultado

La familia de albaranes, pedidos, facturas y devoluciones comparte ahora
el ancestro `TfrmMtoDocumento`, la configuración
`TConfiguracionDocumento` y el contrato `IEstrategiaDocumento`.

El prerrequisito de la Fase 3 también queda cerrado para facturas:
`TfrmMtoFacturasBase` baja de 4.008 líneas, 133 métodos y 49 campos a
1.779 líneas, 104 métodos y 10 campos. La edición de líneas, la creación
de columnas y la coordinación de presentación tienen colaboradores con
ciclo de vida explícito.

## Configuraciones migradas

| Documento | Contador | Movimiento | Stock | Asiento | Verifactu |
|-----------|----------|------------|------:|---------|-----------|
| Albarán venta | AV | AV / S | -1 | No | No |
| Albarán compra | AB | AC / E | +1 | No | No |
| Pedido venta | PE | — | 0 | No | No |
| Pedido compra | PC | — | 0 | No | No |
| Factura venta | FC | FC / S | -1 | Sí | Sí |
| Factura compra | FP | — | 0 | Sí | No |
| Devolución compra | DC | DC / S | -1 | No | No |

La factura de compra no vuelve a mover stock: la entrada ya se produjo
en el albarán. La devolución de venta continúa representándose mediante
factura rectificativa.

## Migración

1. Albaranes de venta y compra.
2. Pedidos de venta y compra.
3. Facturas de venta y compra.
4. Devoluciones de compra.

Los siete formularios heredan de `TfrmMtoDocumento`. Las series y
contadores se obtienen de la configuración. Los servicios de movimientos
consultan la estrategia para el código, el sentido y el signo de stock.
No se modificaron los grids pivote.

Las factorías y alias temporales de configuración que vivían en
`inLibValidacionDocumento` se retiraron al migrar el último consumidor.
La única estructura de configuración pública es
`TConfiguracionDocumento`.

## Validación

- Aplicación: Win32 y Win64, Debug y Release.
- Pruebas DUnitX: 500 de 500 en las cuatro combinaciones.
- Guardarraíl de tamaño: 1.779 líneas, 104 métodos y 10 campos para
  `TfrmMtoFacturasBase`.
- Búsqueda de literales: los formularios migrados ya no deciden códigos
  de serie o movimiento.
- Base de datos: sin cambios de esquema y sin modificar
  `factuzam_original.sql`.

## Criterio de salida

Un tipo nuevo se incorpora con una configuración y, si necesita reglas
distintas, una estrategia. No requiere copiar otro formulario.
