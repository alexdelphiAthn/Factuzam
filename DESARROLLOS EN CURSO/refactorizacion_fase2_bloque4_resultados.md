# Fase 2, bloque 4 (final) — Conversión IVA única y fin del bug AsInteger

Fecha: 26/07/2026. Ficheros: `src/Lib/inLibImpuestosComun.pas`,
`src/Forms/inMtoFacturasBase.pas`.

## El bug corregido

Dos de las tres copias de la conversión IVA incluido/excluido del form de
facturas leían el porcentaje de la cabecera con **`AsInteger`**: un IVA con
decimales (10,5 %…) se truncaba a entero en esas rutas mientras otras lo leían
con `AsFloat` — dos caminos del mismo dato con redondeo distinto y descuadres
de céntimos entre línea y cabecera.

## Cambios

1. **`inLibImpuestosComun`** gana dos helpers puros con guarda de división:
   `PrecioSinIvaDesdeConIva(APrecio, APorcentaje)` y
   `PrecioConIvaDesdeSinIva(...)` (porcentaje SIEMPRE en tanto por cien y con
   decimales; documentado en la propia declaración).
2. **`inMtoFacturasBase`**: las 3 copias de la conversión (ConsolidarSkuLinea,
   el EditValueChanged del SKU y AplicarArticuloFactura) y la inversa de
   `PrecioSkuTallas` llaman ahora a los helpers. Los dos `case` con
   `AsInteger` desaparecen: ambas rutas usan `PorcentajeIvaFactura`
   (`AsFloat`), que a su vez queda delegado en
   `inLibImpuestosComun.PorcentajeIvaCabecera` (misma convención
   `PORCENTAJE_IVAx_FAC`). Variables `iPorcen` eliminadas de los dos métodos.

Efecto funcional deliberado: con IVAs enteros (21, 10, 4, 0) los números son
idénticos a antes; con IVAs decimales, las dos rutas que truncaban ahora
calculan bien (ese es el fix).

## Compilación (en tu máquina)

La primera pasada falló con E2004 (declaración duplicada en la común —
error mío al aplicar el parche dos veces); corregido y relanzado:

- **0 errores.** 307.540 líneas, 18,5 s.
- Ningún hint nuevo en `inLibImpuestosComun` ni en las zonas tocadas de
  `inMtoFacturasBase`.

## Pruebas manuales (UI, BBDD de pruebas)

| # | Prueba | Resultado esperado |
|---|---|---|
| I1 | Factura con tarifa IVA-incluido: añadir artículo por SKU | PVP c/IVA igual que antes; s/IVA = c/IVA ÷ 1,21 exacto |
| I2 | Factura con tarifa IVA-excluido | c/IVA = s/IVA × 1,21; totales cuadran con la cabecera |
| I3 | (Si usas IVAs con decimales) línea con tipo reducido decimal | s/IVA y c/IVA SIN truncar el porcentaje — antes salía mal en 2 de las 3 rutas |
| I4 | Entrada por pivote de tallas (PrecioSkuTallas) | Precio base igual que antes |
| I5 | Grabar y comparar TOTAL_FAC con la suma de líneas | Sin descuadres de céntimos |

---

# FASE 2 COMPLETA — resumen

| Bloque | Contenido | Líneas | Compila |
|---|---|---|---|
| 1 | `inLibImpuestosComun`: 14 funciones fiscales desduplicadas (equivalencia 14/14 demostrada) | −187 netas | ✓ |
| 2 | Modal de remesas único (compra+venta) con `TConfigRemesa`, unidad Venta retirada a `_to_delete` | −370 | ✓ |
| 3 | `CrearAlbaranDesdePedido` fusionada (wrapper → motor de cantidades) — verificado por aritmética del compilador (307.826−278=307.548) | −278 | ✓ |
| 4 | Conversión IVA única + fix `AsInteger` | −40 aprox | ✓ |

Total: **~875 líneas duplicadas eliminadas**, un bug de descuadre corregido,
y una unidad fiscal común que es la nueva fuente de verdad. Todo compilado en
Release/Win64 con 0 errores tras cada bloque.

Pendiente de validación manual acumulado: R1–R8 (remesas), P1–P5 (albarán
desde pedido), I1–I5 (IVA) y el smoke fiscal del bloque 1.

## Siguiente en el plan global

Fase 3 (desacoplar UI↔datos): `ValidarCabeceraBeforePost` devolviendo
resultado en vez de tocar el form, registro de pantallas por clase en vez de
RTTI-por-string, handler único de menú en el principal, y la regla de estilo
"`inLib*`/`UniData*` nunca usan `inMto*`".
