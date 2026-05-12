# Ampliación en runtime de `vi_articulos_skus_etiquetas`

Notas de diseño sobre cómo hacer que la vista de etiquetas pueda **incorporar
nuevas propiedades o atributos** sin recompilar el ejecutable de Factuzam.
Hoy la vista (definida en `etiquetas_articulos.sql`) tiene un conjunto fijo
de columnas pivotadas; este documento describe el problema y plantea la
solución.

---

## 1. El issue

La vista `vi_articulos_skus_etiquetas` expone columnas **hardcoded** para
atributos y propiedades:

```
ATR_CO, ATR_TAL
PROP_MARCA, PROP_MATERIAL, PROP_TEMPORADA,
PROP_GENERO, PROP_ESTILO, PROP_ORIGEN, PROP_COMPOSICION
```

Si el usuario:

- Da de alta un nuevo atributo (p.ej. `'DUR'` Duración en
  `fza_variaciones_atributos`), o
- Da de alta una nueva propiedad (p.ej. `'COLECCION'` en `fza_propiedades`),

…no aparece como columna en la vista. Como solución actual queda el
campo agregado `PROPIEDADES_TXT` / `ATRIBUTOS_TXT`, donde la cadena
`"Marca: Zara | Material: Algodón | Colección: PV26"` sí contiene la
propiedad nueva. Pero **no** se puede referenciar como columna individual
desde FastReport, ni filtrar en SQL por ella.

Conclusión: ampliar la vista hoy obliga a:

1. Editar `etiquetas_articulos.sql` (añadir el `MAX(CASE …)` con el código
   nuevo).
2. Volver a desplegar la vista contra la BBDD.
3. **Recompilar** Factuzam si quieres mapear la columna desde Delphi, o
   editar el `.frx` del informe para que la muestre.

El usuario quiere evitar el paso 3 (y, a poder ser, también el 1).

---

## 2. Casos a cubrir

Distinguimos tres niveles de "ampliar":

| Caso | Origen del dato | ¿Toca recompilar Delphi? |
|------|-----------------|--------------------------|
| **A** — Nueva propiedad o atributo en sus tablas maestras (`fza_propiedades`, `fza_variaciones_atributos`). | Datos ya existentes en la BBDD. | **No**, si reconstruimos la vista con un SP. |
| **B** — Columna calculada arbitraria (p.ej. `PRECIO_FINAL_ARTTAR * 0.21`, `CONCAT(MARCA,'/',TEMPORADA)`). | Expresión SQL libre. | **No**, si guardamos la expresión en una tabla de configuración y el SP la concatena. |
| **C** — Join a una tabla nueva totalmente ajena (p.ej. `fza_clientes_favoritos`). | Tabla nueva. | **Sí**: el SP de reconstrucción puede leer la config, pero el modelo de
configuración tendría que prever el `JOIN`, y la consulta runtime de
`CrearDataSetEtiquetasArt` también. |

Lo más realista es resolver A (cubre el 90 % de "una propiedad nueva en
etiqueta") y dejar B como opcional.

---

## 3. Solución propuesta (Caso A)

### 3.1 Mover la vista a un SP que la regenera

Sustituir la `CREATE VIEW` estática por un **procedimiento almacenado** que:

1. Recorre `fza_propiedades WHERE ESACTIVO_PROP = 'S'`.
2. Por cada `CODIGO_PROP_ARTPROP` añade un fragmento

   ```sql
   MAX(CASE WHEN ap.CODIGO_PROP_ARTPROP = '<COD>'
            THEN COALESCE(pv.PV, ap.VALOR_LIBRE_ARTPROP)
       END) AS PROP_<COD>
   ```

3. Recorre `fza_variaciones_atributos` (o `SELECT DISTINCT ID_VA_AV FROM
   fza_atributos_valores`) y por cada `ID_ATB_VA` añade

   ```sql
   MAX(CASE WHEN av.ID_VA_AV = '<COD>' THEN av.AV END) AS ATR_<COD>
   ```

4. Concatena todo en una sentencia `CREATE OR REPLACE VIEW
   vi_articulos_skus_etiquetas AS …` y la ejecuta con `PREPARE` /
   `EXECUTE` dinámico.

Esqueleto:

```sql
DELIMITER $$
CREATE OR REPLACE PROCEDURE PRC_REGENERAR_VISTA_ETIQUETAS()
BEGIN
  DECLARE v_cols_prop TEXT DEFAULT '';
  DECLARE v_cols_atr  TEXT DEFAULT '';
  DECLARE v_sql       TEXT;

  -- 1) Columna por propiedad activa
  SELECT GROUP_CONCAT(
           CONCAT(
             'MAX(CASE WHEN ap.CODIGO_PROP_ARTPROP = ',
             QUOTE(CODIGO_PROP_ARTPROP),
             ' THEN COALESCE(pv.PV, ap.VALOR_LIBRE_ARTPROP) END) AS PROP_',
             CODIGO_PROP_ARTPROP
           ) SEPARATOR ',\n  '
         )
    INTO v_cols_prop
    FROM fza_propiedades
   WHERE ESACTIVO_PROP = 'S';

  -- 2) Columna por atributo de variaciones
  SELECT GROUP_CONCAT(DISTINCT
           CONCAT(
             'MAX(CASE WHEN av.ID_VA_AV = ', QUOTE(ID_ATB_VA),
             ' THEN av.AV END) AS ATR_', ID_ATB_VA
           ) SEPARATOR ',\n  '
         )
    INTO v_cols_atr
    FROM fza_variaciones_atributos;

  -- 3) Componer el CREATE VIEW
  SET v_sql = CONCAT(
    'CREATE OR REPLACE VIEW vi_articulos_skus_etiquetas AS\n',
    'WITH sku_atrib AS (\n',
    '  SELECT sa.CODIGO_UNIDAD_SKU_SA AS CODIGO_UNIDAD_SKU,\n',
    '         ', IFNULL(v_cols_atr, 'NULL AS ATR_DUMMY'), ',\n',
    '         GROUP_CONCAT( … ) AS ATRIBUTOS_TXT,\n',
    '         GROUP_CONCAT( … ) AS DESCRIPCION_SKU\n',
    '    FROM fza_atributos_sku sa …\n',
    '),\n',
    'art_prop AS (\n',
    '  SELECT ap.CODIGO_ART_ART,\n',
    '         ', IFNULL(v_cols_prop, 'NULL AS PROP_DUMMY'), ',\n',
    '         GROUP_CONCAT( … ) AS PROPIEDADES_TXT\n',
    '    FROM fza_articulos_propiedades ap …\n',
    '), cb_prin AS ( … )\n',
    'SELECT sku.*, sa.*, apr.*, ap.*, prv.*, cb.* …'
  );

  PREPARE stmt FROM v_sql;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
END$$
DELIMITER ;
```

El SP es **idempotente**: se puede llamar tantas veces como haga falta.

### 3.2 Cuándo se llama

Tres niveles de automatización, de menos a más cómodo:

- **Manual**: el administrador ejecuta `CALL PRC_REGENERAR_VISTA_ETIQUETAS();`
  desde su cliente SQL después de añadir una propiedad o atributo. Cero
  cambios en Delphi.
- **Botón en `inMtoPropiedades` / `inMtoVariaciones`**: añadir un
  `cxButton "Regenerar etiquetas"` que invoque el SP. Cambia Delphi sólo
  una vez.
- **Automático**: añadir un `AfterPost` / `AfterDelete` en `inMtoPropiedades`
  y `inMtoVariaciones` que llame al SP. El usuario no se entera, y la
  vista se mantiene siempre alineada con el catálogo.

Mi recomendación es la opción 3 — el `AfterPost` ya existe en el patrón
del proyecto (`oDmConn.ActualizarUserTimeModif`, etc.), así que añadir
una llamada a un SP es de una línea.

### 3.3 Impacto en Delphi

El cambio en Delphi es mínimo:

- En `CrearDataSetEtiquetasArt` la consulta hace `SELECT eti.*` sobre
  `vi_articulos_skus_etiquetas`. Si la vista cambia y aparecen nuevas
  columnas, el `SELECT *` las arrastra automáticamente al
  `TClientDataSet`. **No** hace falta tocar `TField`s a mano: los crea
  el DataSetProvider en cada apertura.
- El `.frx` del informe sí debe colocar el `[EtiquetasArt."PROP_COLECCION"]`
  donde quieras que aparezca. Eso es edición desde el propio Factuzam,
  con el diseñador integrado (botón "Editar" del modal de impresión y
  guardado del layout por perfil de usuario). No requiere recompilar.

---

## 4. Solución propuesta (Caso B — opcional)

Para soportar **columnas calculadas arbitrarias** definidas por el usuario:

```sql
CREATE TABLE fza_vista_etiquetas_columnas (
  CODIGO_VEC      varchar(40) NOT NULL,        -- nombre de la columna
  EXPRESION_VEC   varchar(500) NOT NULL,       -- p.ej.
                                               -- 'CONCAT(art.DESCRIPCION_ART," ",sa.ATR_CO)'
  ORDEN_VEC       int NULL,
  ESACTIVO_VEC    varchar(1) NOT NULL DEFAULT 'S',
  INSTANTE_ALTA   timestamp NOT NULL DEFAULT current_timestamp(),
  USUARIO_ALTA    varchar(100) NOT NULL,
  INSTANTE_MODIF  timestamp NOT NULL DEFAULT current_timestamp()
                                       ON UPDATE current_timestamp(),
  USUARIO_MODIF   varchar(100) NOT NULL,
  PRIMARY KEY (CODIGO_VEC)
);
```

`PRC_REGENERAR_VISTA_ETIQUETAS` añade un bloque adicional:

```sql
SELECT GROUP_CONCAT(CONCAT('(', EXPRESION_VEC, ') AS ', CODIGO_VEC)
                    SEPARATOR ',\n  ')
  INTO v_cols_libres
  FROM fza_vista_etiquetas_columnas
 WHERE ESACTIVO_VEC = 'S'
 ORDER BY COALESCE(ORDEN_VEC, 999), CODIGO_VEC;
```

Y un mantenimiento Delphi sencillo (`inMtoVistaEtiquetasColumnas`,
heredando de `inMtoGen`) deja al usuario editar las expresiones.

⚠ Riesgos:

- El `EXPRESION_VEC` se concatena tal cual en SQL. Inyección potencial si
  el formulario no restringe quién la edita; conviene exigir grupo
  Administrador.
- Hay que validar que la expresión compile (intentar `SELECT (<expr>)
  FROM vi_articulos_skus_etiquetas LIMIT 0` antes de aceptarla).

---

## 5. Caso C — fuera de alcance

Joins a tablas completamente nuevas (no derivadas del catálogo de
propiedades/atributos) sí requieren tocar Delphi: la consulta runtime de
`CrearDataSetEtiquetasArt` debe conocer la tabla, y la lista de columnas
de la `WHERE`/`ORDER BY` también. Para esto, hoy por hoy, lo más limpio
es seguir editando `etiquetas_articulos.sql` y recompilar.

Si en el futuro se necesita, la generalización pasa por una tabla
`fza_vista_etiquetas_joins` análoga a la del Caso B, con `TABLA`, `ALIAS`,
`ON_CLAUSE` — pero entra ya en terreno de "mini-ORM en SQL" y conviene
discutirlo antes de implementarlo.

---

## 6. Hoja de ruta sugerida

1. Crear `PRC_REGENERAR_VISTA_ETIQUETAS` y dejarla operando contra el
   catálogo actual (Caso A) — script en
   `DESARROLLOS EN CURSO/etiquetas_articulos.sql`, sección 2.
2. Llamar al SP desde el `AfterPost`/`AfterDelete` de las pantallas de
   propiedades y de variaciones.
3. Evaluar con los usuarios si necesitan el Caso B antes de implementarlo.

Con la 1 y la 2 hechas, dar de alta una propiedad nueva en
`inMtoPropiedades` deja la vista de etiquetas lista para que el usuario
coloque su columna en el `.frx` desde el botón "Editar" del modal de
impresión, **sin tocar el ejecutable**.
