# Fixture de familias PrestaShop ZZPS260815

Este fixture local permite probar cuántos niveles de familia se publican al
dar de alta un artículo en PrestaShop. No contiene llamadas HTTP y el `setup`
deja el artículo fuera de web para que el alta se provoque desde FactuZam.

## Identificadores

- Familia padre: `ZZPS260815` — `TEST PS PADRE 260815`.
- Familia hoja: `ZZPS260815H` — `TEST PS HOJA 260815`.
- Artículo: `ZZPS260815C` — `TEST DEMO CAMISA PS 260815`.
- Usuario de auditoría inicial: `ZZPS260815_FIXTURE`.

El diseño inicial llamaba `ZZPS260815P` al padre, pero no cabe en
`fza_articulos_familias.CODIGO_SUBFAMILIA_FAM`, que en el esquema real es
`varchar(10)`. Se usa `ZZPS260815` para que tanto `CODIGO_PADRE_FAM` como el
campo legacy `CODIGO_SUBFAMILIA_FAM` de la hoja apunten al mismo padre sin
truncamiento. El alta PrestaShop recorre `CODIGO_PADRE_FAM`.

## Contenido del setup

El script [ZZPS260815_familias_setup.sql](ZZPS260815_familias_setup.sql):

- valida el esquema y que no exista ningún identificador reservado;
- exige que `DEMO-CAMISA` tenga 12 SKU activos, 24 atributos de SKU, 5
  atributos básicos, 3 tarifas y una foto general;
- inserta las dos familias y clona con listas de columnas explícitas solo los
  datos mínimos del artículo;
- renombra el artículo y todos los SKU sin usar un `LIKE` abierto;
- reutiliza únicamente el nombre físico de la foto general de `DEMO-CAMISA`;
- no copia stock, propiedades, costes, códigos, movimientos ni fotos de SKU;
- deja `ESACTIVO_ART='S'`, `ESWEB_ART='N'`, `ESVARIACION_ART='S'` y
  `TIPO_VARIACION_ART='TC'`;
- ejecuta todo el DML en una transacción y hace `ROLLBACK` y `SIGNAL` ante
  cualquier incumplimiento.

Postcondición esperada: 2 familias, 1 artículo, 12 SKU, 24 atributos de SKU,
5 atributos básicos, 3 tarifas, 1 foto general y 0 filas de stock del fixture.

## Prueba de niveles

1. Ejecutar el `setup` con FactuZam cerrado y comprobar que termina con
   `RESULTADO=PASA`.
2. Configurar `Niveles de familia al crear artículos` en `0`, marcar
   `ZZPS260815C` para web desde Artículos y comprobar que se crean padre y
   hoja en PrestaShop.
3. Para probar el valor `1`, restaurar el checkpoint local y de PrestaShop,
   volver a ejecutar el `setup`, fijar el parámetro en `1` y repetir el alta.
   Debe publicarse solo la hoja bajo la categoría raíz configurada.

No se recomienda reutilizar el mismo producto remoto entre las dos variantes:
la localización por `reference` convertiría la segunda ejecución en una
actualización y dejaría de validar un alta limpia.

## Cleanup y recuperación

El script [ZZPS260815_familias_cleanup.sql](ZZPS260815_familias_cleanup.sql)
borra en este orden: fotos, atributos de SKU, stock si existe, tarifas,
atributos básicos, SKU, artículo, familia hoja y familia padre. Es idempotente
y se niega a borrar filas que no conserven la marca de auditoría del fixture.

El cleanup no borra `fza_prestashop_cola`, su historial ni el producto remoto.
Si el artículo ya se marcó para web, detecta la fila de cola y termina con
`SIGNAL` para conservar la trazabilidad. Después de una prueba funcional, la
recuperación recomendada es restaurar conjuntamente el checkpoint completo de
FactuZam y el de PrestaShop guardado en `tmp/prestashop_e2e`, o revisar y
retirar la trazabilidad y el producto remoto mediante un procedimiento
separado y explícitamente autorizado.

Aunque se ejecute antes de encolar, el cleanup no reduce el `AUTO_INCREMENT`
de `fza_articulos_tarifas`: los tres identificadores consumidos quedan como un
hueco normal. Para recuperar un estado idéntico bit a bit también debe usarse
el checkpoint completo.

## Validación realizada

Validado el 15 de agosto de 2026 con MariaDB 12.3.2 en una instancia aislada,
cargada desde
`run_20260814_180410_post_alta/factuzam_post_alta.sql`. No se modificaron las
bases activas `factuzam` ni PrestaShop. Resultados:

- primer setup: `PASA`, con conteos `2/1/12/24/5/3/1/0`;
- segundo setup: `SIGNAL` por identificadores existentes, sin duplicar datos;
- cleanup: `PASA` y deja a cero todos los identificadores del fixture;
- segundo cleanup: `PASA`, por tanto es idempotente;
- con una fila de cola sintética: cleanup devuelve `SIGNAL`, conserva las 12
  SKU y no deja la rutina auxiliar instalada.
