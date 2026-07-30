# Inventario de escrituras SQL-3 — sesiones de compra

Fecha de corte: 30/07/2026.

Este inventario delimita las escrituras que permanecen fuera de SQL-3.
No autoriza a sustituirlas mediante perfiles. Su política continúa siendo
SQL base y su migración corresponde a SQL-4 o SQL-5.

## 1. Edición de una sesión

| Transacción lógica | Escrituras | Propietario actual | Límite transaccional |
|---|---|---|---|
| Borrar celdas de una línea | `DELETE fza_compras_sesiones_celdas` | `BorrarCeldasLineaSesion` | Una sentencia atómica; usa la transacción ambiente si existe |
| Copiar distribución entre líneas | `DELETE` destino, `INSERT ... SELECT` origen y `UPDATE` de totales | `CopiarCeldasDistribuidasSesion` | Abre, confirma y revierte solo si la conexión no estaba ya en transacción |
| Aplicar kit de proveedor | Un `DELETE` o `UPSERT` por talla mediante `TGestorGridTallas.PersistirCantidad` | `AplicarKitProveedorALinea` | No existe una unidad de trabajo que abarque el kit completo; cada celda usa la transacción ambiente |
| Reservar código por familia | `SELECT ... FOR UPDATE` y `UPDATE fza_articulos_familias` | `ResolverCodigoFamilia` | Requiere una transacción ambiente para que el bloqueo y el incremento formen una unidad; el helper no la abre |
| Normalizar duplicados internos | Un `UPDATE ... JOIN` de líneas | `NormalizarDuplicadosIntraSesion` | Una sentencia atómica; usa la transacción ambiente si existe |
| Persistir una sesión desde el `TDataModule` | `INSERT`, `UPDATE` y `DELETE` de cabecera y líneas, alta de serie y actualización de totales | `UniDataComprasSesiones` | Operaciones de edición del dataset; no forman parte del contrato de lecturas SQL-3 |

Los dos riesgos que deben resolverse antes de habilitar perfiles de
escritura son el kit parcial y el contador de familia sin unidad de trabajo
propia.

## 2. Materialización

`TMaterializadorComprasSesiones.Ejecutar` es el único propietario de la
transacción completa:

1. inicia `IUnidadTrabajoMaterializacion`;
2. materializa artículos;
3. materializa pedido y/o albarán;
4. registra los documentos y cierra la sesión;
5. confirma una vez;
6. ante cualquier excepción, revierte una vez y registra el error después
   del `Rollback`.

Los adaptadores participantes no hacen `Commit` ni `Rollback`.

| Paso dentro de la unidad de trabajo | Escrituras principales |
|---|---|
| Artículos | artículos, conjuntos asignados, propiedades, valores de atributo, atributos básicos, SKU, atributos de SKU, códigos de barras, proveedor y tarifa |
| Pedido de compra | cabecera, líneas, IVA, totales, pendiente de recibir y vínculo con la sesión |
| Albarán de compra | cabecera, líneas, IVA, totales, cierre y vínculo con la sesión |
| Cierre | estado de `fza_compras_sesiones` y referencias de pedido/albarán |

La operación `RegistrarError` se ejecuta deliberadamente después de
revertir la unidad de trabajo para que el diagnóstico no desaparezca con
el resto de la transacción.

Desde SQL-3.1c, las lecturas auxiliares de estos pasos pertenecen a
`ILecturasMaterializacionComprasSesiones` y a
`RepositorioMaterializacionComprasSesiones`. Los adaptadores de escritura
reciben DTOs o valores escalares; no conservan consultas de lectura ni
exponen `TUniQuery` a través del contrato.

## 3. Reversión

`TRevertidorComprasSesiones.Ejecutar` también posee una única unidad de
trabajo. Dentro de ella:

- elimina líneas y cabeceras de albarán;
- elimina movimientos mediante los procedimientos almacenados;
- elimina vínculos de documentos;
- elimina pendientes de recibir y documentos de pedido;
- reabre la sesión.

Confirma una sola vez al final y revierte toda la operación ante cualquier
excepción.

## 4. Regla para SQL-3

- Las escrituras anteriores no se registran como
  `pesPerfilLecturaConFallback`.
- Una lectura extraída no puede ejecutar efectos laterales.
- `ResolverCodigoFamilia` permanece en el contrato de escritura porque
  incrementa el contador.
- No se añadirá SQL de lectura a `inLibComprasSesiones`,
  `inLibComprasSesionesMaterializar` ni a sus adaptadores de escritura.
- Las dieciséis operaciones de lectura de SQL-3.1c usan
  `pesPerfilLecturaConFallback`; ninguna escritura de este inventario se
  publica en perfiles.
