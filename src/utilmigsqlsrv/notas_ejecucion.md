# Notas de ejecución del FactuzamMigrator

Documenta los contadores que muestra el log del migrador, los motivos
habituales de "saltos" y los errores que puede dar. Toma como ejemplo
una ejecución real (20/05/2026 07:06).

---

## Contadores que aparecen en el log

Al final de cada dominio el migrador escribe:

```
<Dominio>: X leidas, Y insertadas, Z saltadas, W errores.
```

Significado:

| Contador | Qué cuenta |
|----------|------------|
| **Leídas** | Filas devueltas por el SELECT en SQL Server |
| **Insertadas** | INSERT ejecutados con éxito contra MariaDB |
| **Saltadas** | Filas que NO se han insertado **a propósito** (sin error). El motivo varía según el dominio — ver tabla más abajo |
| **Errores** | Filas que FALLARON en el INSERT. El motor escribe el detalle (`! error insertando X: ...`) y, si el dominio fue cancelado, hace ROLLBACK de la transacción del dominio. El resto de dominios sí se ejecutan |

Regla general: `Leídas = Insertadas + Saltadas + Errores` (siempre).

---

## Motivos de salto por dominio

| Dominio          | Motivos posibles de SALTO                                                |
|------------------|--------------------------------------------------------------------------|
| Empresas         | (a) PK ya existe en destino (típico tras cargar el esqueleto: si traía el seed AGRICULTOR con `CODIGO_EMP_EMP='1'` y el legacy también usa `Empresa=1`, salta). |
| Almacenes        | (a) PK ya existe (`CODIGO_ALM_ALM = "E<emp>-A<alm>"` ya en destino).      |
| Clientes         | (a) `Cliente` vacío en origen. (b) PK ya existe (clientes demo del seed 293-321 o `PUBLICO`/`TIENDA`). |
| Proveedores      | (a) PK ya existe. Cuidado: el seed demo trae proveedores Northwind con códigos numéricos `3-23` que **colisionan** con códigos legítimos del legacy. Lo migrado es semánticamente distinto a lo que queda. |
| Familias         | (a) PK ya existe (`CODIGO_FAM_FAM = ocniv.Codigo`).                       |
| Catálogo colores | (a) El AV ya existe en `fza_atributos_valores` (el seed trae NEGRO, BLANCO, ROJO, AZUL, VERDE, AMARILLO, MARRON, GRIS, BEIGE, ROSA → si el origen tiene un color con la misma descripción tras `UPPER+TRIM`, salta para REUTILIZAR el seed canónico). |
| Catálogo tallas  | (a) Igual: el seed trae S/M/L/XL/XXL/3XL/XS/36/37/38/42... → si la talla origen normaliza a la misma, salta. |
| Artículos        | (a) PK ya existe (`CODIGO_ART_ART = ocartp.Articulo`). (b) Artículo con código vacío. |
| Colores por art  | (a) Asignación (CODIGO_ART_AAB, ID_AV_AAB) ya existe. (b) Línea con Articulo o color vacíos. |
| Tallas por art   | (a) Asignación ya existe. (b) Línea con Articulo o talla vacíos.          |

> **Regla mnemotécnica**: "salto = no pasa nada malo, sigo". "Error =
> algo falló, lo grabo en el log y aborto la transacción de ESE
> dominio". Los siguientes dominios pueden ejecutarse igualmente
> (pregunta el motor).

---

## Ejemplo: run del 20/05/2026 07:06 (BBDD `herreras`)

| Migración          | Leídas  | Insertadas | Saltadas | Errores |
|--------------------|--------:|-----------:|---------:|--------:|
| Empresas           |       1 |          0 |        1 |       0 |
| Almacenes          |       6 |          6 |        0 |       0 |
| Clientes           |  11 811 |     11 786 |       25 |       0 |
| Proveedores        |     235 |        214 |       21 |       0 |
| Familias           |     190 |        190 |        0 |       0 |
| Catálogo colores   |      46 |         36 |       10 |       0 |
| Catálogo tallas    |      76 |         62 |       14 |       0 |
| Artículos          |  52 351 |     52 351 |        0 |       0 |
| Colores por art    |  81 376 |     81 324 |       51 |       1 |
| Tallas por art     | 266 462 |    266 462 |        0 |       0 |
| **TOTAL**          | **412 554** | **412 431** | **122** | **1** |

### Detalle de los saltos

**Empresas — 1 salto.** "1 ya existe". El esqueleto cargado desde
`factuzam_original.sql` traía el seed con `CODIGO_EMP_EMP='1'`
(`AGRICULTOR`). El legacy también tiene `Empresa=1`
(`MELITON HERRERAS E HIJOS S.L.`). Colisión de PK → se queda el
seed. **Consecuencia**: en destino la empresa "1" sigue siendo
`AGRICULTOR`, no `MELITON HERRERAS`. Para tener la real:

```sql
-- Borrar el seed antes de migrar:
DELETE FROM fza_empresas WHERE CODIGO_EMP_EMP = '1';
-- ... y re-ejecutar Empresas.
```

**Clientes — 25 saltos.**
- 1 cliente con `Cliente` vacío (registro sucio del origen).
- 24 con códigos `293`-`321` que ya estaban como demo (`PUBLICO`,
  `TIENDA`, `LAURA FERNANDEZ`...) cargados por el seed. Mismo problema
  que con empresas: los del legacy se descartan.

**Proveedores — 21 saltos.**
Códigos `3`-`23` ya en seed (proveedores Northwind: `Exotic Liquids`,
`New Orleans Cajun Delights`, `Tokyo Traders`, ...). En el legacy esos
mismos números son proveedores reales de Herreras (`MANGA RANGLA`,
`CREASUR`...). **Esto es serio**: los datos del seed Northwind no
tienen nada que ver con los reales y debes plantearte borrarlos antes
de migrar:

```sql
DELETE FROM fza_proveedores
 WHERE CODIGO_PRV_PRV BETWEEN '3' AND '23'
   AND USUARIO_ALTA = 'Administrador';
```

**Catálogo colores — 10 saltos.**
El seed trae 10 colores canónicos (NEGRO, BLANCO, ROJO, AZUL, VERDE,
AMARILLO, MARRON, GRIS, BEIGE, ROSA). Cuando el legacy tiene un color
con misma descripción normalizada, el migrador NO duplica — usa el
valor que ya está. Esto es deseable. Los otros 36 (`ROSA PALO`,
`GUINDA`, `GROSELLA`...) se insertan.

**Catálogo tallas — 14 saltos.** Mismo patrón: el seed cubre las
tallas más comunes (S/M/L/XL/XXL/XS y unas pocas numéricas). Las 14
saltos = solapamientos sin pérdida de información.

**Colores por artículo — 51 saltos + 1 error.**
- Los 51 saltos: la pareja `(CODIGO_ART, ID_AV)` ya estaba en destino
  (puede pasar si re-ejecutas o si el seed demo tenía asignaciones).
- El error: artículo `10160149` tiene en `ocartcol` un color con
  `Color='26'` y `ColorBasico` vacío (dato sucio). Mi `LEFT JOIN` a
  `occolor` no encuentra match, cae al fallback `ac.Color='26'`, y al
  buscar `fza_atributos_valores WHERE AV='26'` no existe (lógico: `26`
  no es nombre de color, era un código mal pegado). El motor loguea
  `! color "26" no esta en fza_atributos_valores (articulo 10160149)`
  y sigue. **Recomendado**: comprobar manualmente esa fila en origen:

```sql
SELECT * FROM dbo.ocartcol
 WHERE Articulo = '10160149';
```

---

## Errores ya vistos y cómo se han resuelto

### 1. `'CharacterSet' is not a valid option name for MySQL UniProvider`

Causa: yo había puesto `SpecificOptions['CharacterSet']='utf8mb4'` en
`UMigConn.ConfigurarDestino`. Esa opción no existe en UniDAC.
**Fix**: línea eliminada. UniDAC ya maneja el charset vía
`MySQL.UseUnicode=True`.

### 2. `Invalid value: Auto for option Provider`

Causa: `SpecificOptions['Provider']='Auto'` (origen SQL Server).
Algunas versiones de UniDAC no aceptan `'Auto'` como literal.
**Fix**: línea eliminada. UniDAC escoge el provider por defecto.

### 3. `Data too long for column 'CODIGO_CLI_CLI' at row 1` (cliente `SOL ALVAREZ`)

Causa: `fza_clientes.CODIGO_CLI_CLI` era `varchar(10)` y el legacy
guarda Cliente en `varchar(15)`. Algunos clientes superan los 10.
**Fix**: `DESARROLLOS EN CURSO/widen_codigo_cli.sql` amplia las 4
columnas afectadas a `varchar(20)`:
- `fza_clientes.CODIGO_CLI_CLI`
- `fza_facturas.CODIGO_CLI_FAC`
- `fza_albaranes.CODIGO_CLI_ALB`
- `fza_pedidos.CODIGO_CLI_PED`

### 4. `El token proporcionado a la función no es válido` (destino, 1 vez)

Causa probable: estado transitorio del pool de UniDAC tras un intento
anterior; error genérico de la API de Windows (SSPI / SChannel).
**Fix**: reintentar — se resolvió solo al pulsar de nuevo "Probar
conexión". Si aparece de forma recurrente, cerrar el migrador, esperar
unos segundos y reabrir.

### 5. `Lock wait timeout exceeded` en `facturas` / `facturas_venta_mayor` → `fza_facturas` vacía

Síntoma: el log muestra `FALLO TOTAL en facturas: #HY000 Lock wait
timeout exceeded` (y lo mismo en `facturas_venta_mayor`), y al terminar
`fza_facturas` está **vacía** aunque las cabeceras y líneas llegaron a
insertarse.

Causa: todo el dominio corría en **una sola transacción**. Tras los
INSERT, el post-proceso lanza un `UPDATE` masivo sobre
`fza_movimientos_almacen` (enlace movimiento→factura). Ese `UPDATE`
escaneaba la tabla entera de movimientos porque
`fza_facturas_lineas.NUMERO_MOV_FACLIN` (la columna del JOIN) **no
estaba indexada**, mantenía bloqueos durante minutos y acababa en *lock
wait timeout*. Al propagarse la excepción, el motor hacía **ROLLBACK de
todo el dominio** y borraba también las facturas ya insertadas.

**Fix** (en código, `inLibMigFacturas` e `inLibMigVentasMayor`):
- Se hace **`Commit` de cabeceras y líneas ANTES** del post-proceso, así
  un fallo en los enlaces ya no puede tirar las facturas.
- Los enlaces van envueltos en `try/except`: si fallan se registran en el
  log (`! ERROR ..._enlace ...`) pero las facturas quedan guardadas.
- Antes del enlace se crea el índice `IDX_FACLIN_NUMMOV`
  (`UMigEngine.AsegurarIndice`), de modo que el `UPDATE` resuelve por PK y
  termina en segundos. También está como script idempotente
  `DESARROLLOS EN CURSO/facturas_lineas_indice_movimiento.sql`.

Recomendación adicional: **cerrar la aplicación Factuzam** (y cualquier
otra sesión sobre la misma BBDD) mientras se migra, para no competir por
los bloqueos de `fza_movimientos_almacen`.

---

## Consejos para una migración limpia desde cero

1. **Borrar el seed demo del destino** antes de migrar para evitar las
   colisiones documentadas arriba (clientes 293-321, proveedores 3-23,
   empresa 1). Patrón general:

   ```sql
   DELETE FROM fza_clientes
    WHERE USUARIO_ALTA IN ('DEMO','Administrador');
   DELETE FROM fza_proveedores
    WHERE USUARIO_ALTA IN ('DEMO','Administrador');
   DELETE FROM fza_empresas
    WHERE USUARIO_ALTA IN ('DEMO','Administrador');
   ```

   El migrador estampa `USUARIO_ALTA = 'MIGRADOR'` (o lo que pongas en
   la casilla "Usuario para auditoría"), así que ese filtro no tocará
   nunca lo migrado.

2. **Aplicar todos los scripts de `DESARROLLOS EN CURSO/`** que tengan
   pendientes el migrador antes de tirar:
   - `proveedores_nombre.sql` (añade `NOMBRE_PRV`)
   - `widen_codigo_cli.sql` (amplía `CODIGO_CLI_*`)
   - `facturas_lineas_indice_movimiento.sql` (índice que evita el *lock
     wait timeout* del enlace de facturas; el migrador también lo crea solo)

3. **Repasar tras la primera ejecución** los registros con `! error
   insertando ...` en el log y decidir si hay que limpiar el origen,
   ampliar otra columna o cambiar el mapeo.

4. **El migrador es idempotente**: re-ejecutarlo no rompe nada. Lo que
   ya existe se cuenta en "Saltadas". Esto facilita corregir y volver
   a tirar.
