# Fase 2 — Lecturas auxiliares de facturas

Fecha de cierre técnico: 31/07/2026.

## Alcance

Las siete lecturas SQL de `inLibFacturas` se han movido a
`UniDataFacturasLecturas`. El dominio accede mediante
`IRepositorioLecturasFactura`, con resultados primitivos o `TDataSet`
propiedad del llamador.

El puerto cubre:

- decisión de mostrar SKU y recuento de líneas;
- configuración de IVA y retención vigente;
- IVA agrícola;
- datos de cliente con tarifa y datos de empresa.

La API pública de `inLibFacturas` no cambia. `TFacturaTotales` resuelve el
repositorio de forma diferida, de modo que los cálculos puros con conexión
nula no necesitan infraestructura.

## Resultado medido

- `inLibFacturas`: 7 sentencias menos y cero SQL literal;
- total del árbol `inLib*`: 169 sentencias en 55 units;
- dependencias `inLib*` hacia `UniData*`: 0;
- tres pruebas nuevas validan la delegación y la ausencia de fábrica;
- DUnitX Debug Win64: 448 de 451 pruebas pasan.

Los tres fallos restantes son los ya conocidos del catálogo SQL:
dos expectativas de 120 frente a 123 registros y una de 7 frente a 10
lecturas de Caja.

No se han movido escrituras ni ampliado transacciones. Las escrituras de
cierre continúan bloqueadas hasta fijar sus límites transaccionales y
contar con una prueba de rollback.
