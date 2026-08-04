# Series de empresa por periodo natural

La serie configurada conserva dos valores:

- `EMPSER`: serie base y valor de respaldo.
- `SERIE_TOKENIZADA_EMPSER`: patrón opcional introducido por el usuario.

Los tokens reservados, sensibles a mayúsculas, son:

- `yyyy`: año natural con cuatro cifras.
- `q`: número de trimestre entre 1 y 4.
- `mm`: número de mes con dos cifras.
- `dd`: día del mes con dos cifras.

Ejemplos para el 4 de agosto de 2026:

- `A1.yyyy` produce `A1.2026`.
- `Tq.A1.yyyy` produce `T3.A1.2026`.
- `yyyy.T2.A1` produce `2026.T2.A1`; aquí `T2` es texto fijo.
- `A1.yyyy.mm` produce `A1.2026.08`.
- `yyyy.mm.dd` produce `2026.08.04`.

Cada token puede aparecer como máximo una vez. Una serie tokenizada sin tokens
reconocidos, o con alguno repetido, se rechaza en el mantenimiento. La vista
también aplica esta defensa y devuelve `EMPSER` si encuentra datos inválidos.

La sustitución solo se activa cuando la empresa tiene
`ESTOKENS_CALENDARIO_NATURAL_EMP = 'S'`. Los documentos históricos no se
renombran: la serie queda guardada como texto en cada documento. Las búsquedas
dependientes de la fecha del documento resuelven los tokens con esa fecha.

El cambio de año, trimestre, mes o día se basa en `CURDATE()` del servidor
MariaDB. Las altas realizadas con "Añadir serie a todos" dejan las fechas de
vigencia vacías para que no haya que renovarlas en cada periodo.

Al usar por primera vez una serie resuelta nueva,
`PRC_GET_NEXT_CONT_FACT_SERIE` crea su contador automáticamente. Cada serie
resultante mantiene por tanto una numeración independiente.

## Alta para todos los documentos

El diálogo solicita almacén, caja y una serie tokenizada base; ya no solicita
fechas. La combinación puede repetirse para asignar una serie distinta a cada
almacén y caja. La máscara base admite hasta 11 caracteres porque las facturas
reservan el último para distinguir su subtipo.

Para `FC` se crean tres series independientes. La máscara base se reserva para
`SIMPLIFICADA`, la más habitual; se añade `N` para `NORMAL` y `R` para
`RECTIFICATIVA`. Por ejemplo, la máscara `Tq.A1.yyyy` produce en el tercer
trimestre de 2026 las series `T3.A1.2026`, `T3.A1.2026N` y `T3.A1.2026R`.
Los demás tipos documentales también conservan la máscara sin sufijo.

El almacén se guarda en todas las series creadas. La caja solo se guarda en
los tipos `VE`, `DE`, `DV`, `TR` y `TA`. Los pedidos y albaranes reciben la
serie del almacén, pero siempre dejan la caja vacía. Los ingresos, los gastos
y los arqueos no reciben una numeración documental nueva.

Los depósitos sí conservan su ubicación operativa. Su carga en el TPV, su
búsqueda y modificación, el arqueo y los informes se limitan a la empresa,
almacén y caja que los originaron. El cierre y el aumento de anticipo se hacen
por el identificador exacto del depósito y verifican también esa ubicación.

## Despliegue

1. Ejecutar `series_ejercicio_natural.sql` sobre la BBDD de destino.
2. Ejecutarlo una segunda vez para comprobar su idempotencia.
3. Activar el indicador y escribir las series tokenizadas que se necesiten.

El script no activa empresas, no precarga patrones ni modifica series existentes.
