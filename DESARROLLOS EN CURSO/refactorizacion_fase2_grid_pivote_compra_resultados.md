# Fase 2 — Persistencia del pivote de compra

Fecha de cierre técnico: 31/07/2026.

## Alcance

Se ha retirado de `inLibGridPivoteCompra` todo el SQL literal que resolvía
colores, validaba sistemas de tallas, cargaba el pivote y aseguraba SKUs.
La unit conserva la coordinación del grid y su API pública.

La separación queda formada por:

- `IRepositorioGridPivoteCompra`, puerto propio de infraestructura;
- `UniDataGridPivoteCompraRepositorio`, adaptador UniDAC;
- `TDataSet` con propiedad del llamador para las lecturas tabulares;
- tipos primitivos para búsquedas y escrituras, sin records de negocio.

La fábrica se registra desde el adaptador y falla de forma explícita si la
aplicación no ha instalado una implementación.

## Resultado medido

- `inLibGridPivoteCompra`: 17 construcciones SQL menos y cero SQL literal;
- total del árbol `inLib*`: 176 sentencias en 56 units;
- dependencias `inLib*` hacia `UniData*`: 0;
- variables globales de interfaz y bloques `except` vacíos: 0;
- clasificación SQL: 102 literales fijos, 3 identificadores autorizados y
  0 valores externos concatenados.

No se ha cambiado el alcance transaccional de las escrituras existentes.
Este trabajo no desbloquea las escrituras de cierre: siguen pendientes de
fijar límites transaccionales y demostrar rollback.

## Verificación

- aplicación: Debug Win64 y Release Win32/Win64 compilan;
- pruebas: Debug Win64 y Release Win32/Win64 compilan;
- dos pruebas nuevas validan el registro de fábrica sin conexión real y el
  fallo explícito cuando falta la implementación;
- DUnitX: 438 de 441 pruebas pasan en Win32 y Win64.

Los tres fallos restantes son los ya conocidos del catálogo SQL:
dos expectativas de 120 frente a 123 registros y una de 7 frente a 10
lecturas de Caja. No se han introducido fallos del pivote.

Los trinquetes de tamaño, flujos largos y acoplamiento conservan fallos
ajenos a este alcance: `TfrmMtoOpeCaja` supera su tope, no hay una
implementación única de `GuardarRegistroNoVerifactu` y `inLibLog` tiene
fan-in 85 frente a 84.
