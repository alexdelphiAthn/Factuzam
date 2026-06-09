# Filtro de familias en informes como árbol (no como lista)

Cambio de frontend en `inMtoModalImpMultiFiltro` (base de los modales de
impresión con filtros múltiples). Sin cambios de esquema ni de SP.

## Qué cambia

La pestaña **Familias** de los informes pasa de ser un *checklist plano*
a un **árbol jerárquico**: se pinta la jerarquía padre→subfamilias y el
usuario marca el padre o el hijo según convenga. **Marcar una familia
incluye en cascada todas sus subfamilias**, así que seleccionar el padre
equivale a seleccionar toda su rama.

- Control: `TcxTreeList` no ligado creado en código (mismo patrón que
  `inMtoPermisosArbol`), con columnas *Familia* (nombre, con la sangría
  del árbol), *Incluir* (checkbox) y *Código*.
- Jerarquía: `CODIGO_SUBFAMILIA_FAM` (la "Familia Padre" del
  mantenimiento `inMtoFamilias` y del selector `inMtoModalSelFamilia`).
  Una familia cuelga de la raíz si no tiene padre o si su padre no
  existe (huérfana). Guarda anticíclica por código ya colocado.
- Marcado: doble clic o barra espaciadora alternan el nodo enfocado y
  propagan la marca a la rama. Sin marcar nada = todas (convención del
  resto de filtros).
- Buscador: filtra por nombre o código mostrando el nodo si él o algún
  descendiente coincide. **No** toca las marcas, así una búsqueda no
  descarta selecciones ocultas.

## Por qué cascada en la UI y no solo el código del padre

`CSVFamilias` devuelve **todos** los códigos marcados (padre + rama). Los
SP de informes (`PRC_GET_BALANCE_ALMACEN_SIN_TALLAS`,
`..._TALLAS`, movimientos de ventas) filtran con
`FIND_IN_SET(CODIGO_FAM_FAM, p_FAMILIAS)` y luego intentan expandir la
descendencia con un CTE recursivo sobre **`CODIGO_PADRE_FAM`**. Devolver
la rama completa desde la UI hace que el filtro sea correcto tanto si
`CODIGO_PADRE_FAM` está poblado como si no, sin tocar los SP.

## Inconsistencia detectada (pendiente, fuera de este cambio)

La app modela la jerarquía de familias en `CODIGO_SUBFAMILIA_FAM`, pero
los SP de informes recorren la descendencia y agrupan "por nivel de
familia" usando `CODIGO_PADRE_FAM`, que en el dump actual está a NULL.
Resultado: la *expansión de descendencia* del SP es hoy un no-op y la
*agrupación por familia por nivel* no refleja la jerarquía real.

Este cambio de UI ya deja el **filtrado** correcto (manda la rama
explícita). Para que la **agrupación por nivel** funcione habría que, en
un script idempotente aparte:

1. Poblar `CODIGO_PADRE_FAM` desde `CODIGO_SUBFAMILIA_FAM`
   (y mantenerlo sincronizado), o
2. Cambiar los CTE de los SP para que usen `CODIGO_SUBFAMILIA_FAM`.

Se deja anotado para decidirlo; no se toca aquí para no mezclar un
cambio de SP/datos con un cambio de pantalla.
