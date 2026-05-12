# Renombrado de identificadores con líneas inabarcables

Tras pasar la utilidad `Ancho80` (en `src/utilfmt80/`) sobre todo el código
fuente del proyecto quedan **113 líneas > 80 columnas**. La inmensa mayoría
son por **identificadores autogenerados por DevExpress** que aún no se han
renombrado conforme exige §5.3 del `LIBRO_DE_ESTILO_DELPHI.md`:

> ### 5.3 Componentes auto-numerados — NO se aceptan
> DevExpress crea por defecto nombres como `cxGridDBColumn37`, `pnl1`,
> `cxgrdbclmn1`. **Estos hay que renombrarlos antes de hacer commit**.

Este documento es el **inventario de renombrados pendientes** que cerrarían
o reducirían drásticamente esos 113 casos. Cada renombrado toca:

- El `.pas` (declaración del campo en la clase, referencias).
- El `.dfm` (definición `object`, referencias a `OnXxx`/`PropertiesXxx`).
- Los manejadores de evento asociados (que arrastran el sufijo del campo).

---

## 1. Resumen

| Categoría                                          | Casos | Estado    |
|----------------------------------------------------|------:|-----------|
| Columnas de grid (`cxgrdbclmn...`)                 |    23 | Renombrar |
| `TableView` autonumerados (`tv2`, `tv3`...)        |     2 | Renombrar |
| Manejadores de evento `xxxPropertiesEditValue...`  |     4 | Cascada(*)|
| URLs largas en comentarios                         |     2 | Aceptar   |
| Comentarios decorativos `// ====`                  |     7 | Acortar   |
| Continuaciones de wrap intrínsecamente largas      |    ~50 | Caso a caso |

(*) Se resuelven solos al renombrar la columna padre (los nombres de
método de evento son `<NombreComponente>PropertiesEditValueChanged`).

---

## 2. Columnas de grid (`cxgrdbclmn...`)

Patrón canónico §5.3:

```
<nombreDelTV><NOMBRE_COLUMNA>

ej: tvFacturacionTOTAL_LIQUIDO_FACTURA
    tvLineasFacturacionCANTIDAD_LINEA
```

### 2.1 `src/Forms/inMtoFamilias.{pas,dfm}`  —  TV padre: `tvLineasFacturacion`

| Línea | Nombre actual                                                       | Nombre propuesto                                            |
|------:|---------------------------------------------------------------------|-------------------------------------------------------------|
| 77    | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA`      | `tvLineasFacturacionCODIGO_ARTICULO_LINEA`                  |
| 78    | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA` | `tvLineasFacturacionDESCRIPCION_ARTICULO_LINEA`             |
| 79    | `cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`   | `tvLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`   |
| 81    | `cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA`| `tvLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA`|
| 83    | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA` | `tvLineasFacturacionPRECIOVENTA_ARTICULO_LINEA`             |

> **Nota**: las columnas 79 y 81 superan 80 col **incluso renombradas** porque
> el sufijo SQL `_ARTICULO_FACTURA_LINEA` es muy largo. Ver §3 para la
> propuesta de abreviar a `_ARTFACLIN` en BBDD (encaja con la convención
> `_FACLIN` ya usada en otras tablas).

### 2.2 `src/Forms/inMtoFormasdePago.{pas,dfm}`  —  TV padre: `tvLineasFacturacion`

| Línea | Nombre actual                                                       | Nombre propuesto                                            |
|------:|---------------------------------------------------------------------|-------------------------------------------------------------|
| 153   | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA`      | `tvLineasFacturacionCODIGO_ARTICULO_LINEA`                  |
| 154   | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA` | `tvLineasFacturacionDESCRIPCION_ARTICULO_LINEA`             |
| 159   | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA` | `tvLineasFacturacionPRECIOVENTA_ARTICULO_LINEA`             |

### 2.3 `src/Forms/inMtoTarifas.{pas,dfm}`  —  TV padre: `tvLineasFacturacion`

| Línea | Nombre actual                                                       | Nombre propuesto                                            |
|------:|---------------------------------------------------------------------|-------------------------------------------------------------|
| 101   | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA`      | `tvLineasFacturacionCODIGO_ARTICULO_LINEA`                  |
| 102   | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA` | `tvLineasFacturacionDESCRIPCION_ARTICULO_LINEA`             |
| 103   | `cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`   | `tvLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`   |
| 105   | `cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA`| `tvLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA`|
| 107   | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA` | `tvLineasFacturacionPRECIOVENTA_ARTICULO_LINEA`             |

### 2.4 `src/Forms/inMtoGeneradorProcesos.{pas,dfm}`

Caso doblemente roto: además de las columnas con nombre autogenerado, **los
propios `TableView` también tienen nombre autogenerado** (`tv2`, `tv3`). Hay
que renombrar **primero** los TV y **después** las columnas (porque el
prefijo de la columna depende del nombre del TV).

**Paso 1 — renombrar los `TableView`**:

| Línea (`.dfm`) | TV actual | Propuesta                                              |
|---------------:|-----------|--------------------------------------------------------|
| —              | `tv2`     | `tvLineasFacturacion` (si refleja líneas de facturación) o `tvLineasProceso` |
| —              | `tv3`     | `tvLineasFacturacionExt` o `tvLineasProcesoExt` (variante 2 del mismo dominio) |

> Necesita decisión funcional: hay dos TVs casi idénticas, hay que confirmar
> qué semántica tiene cada una antes de elegir nombre. La rejilla principal
> ya usa `tvMetadatostvVista` (también dudoso), así que toca pasar por la
> UI con el formulario abierto y mirar qué muestra cada una.

**Paso 2 — renombrar las columnas** (asumiendo `tv2 → tvLineas1`, `tv3 → tvLineas2`
como ejemplo; ajustar al nombre real elegido):

| Línea | Nombre actual                                                       | Propuesto (ejemplo)                                |
|------:|---------------------------------------------------------------------|----------------------------------------------------|
| 92    | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA1`     | `tvLineas1CODIGO_ARTICULO_LINEA`                   |
| 93    | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA1`| `tvLineas1DESCRIPCION_ARTICULO_LINEA`              |
| 95    | `cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA1`  | `tvLineas1TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`    |
| 96    | `cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA1` | `tvLineas1PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA` |
| 99    | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA1`| `tvLineas1PRECIOVENTA_ARTICULO_LINEA`              |
| 110   | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA11`    | `tvLineas2CODIGO_ARTICULO_LINEA`                   |
| 111   | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA11`| `tvLineas2DESCRIPCION_ARTICULO_LINEA`             |
| 113   | `cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA11` | `tvLineas2TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA`    |
| 114   | `cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA11` | `tvLineas2PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA` |
| 116   | `cxgrdbclmnLineasFacturacionTIPOIVA_ARTICULO_FACTURA_LINEA11`       | `tvLineas2TIPOIVA_ARTICULO_FACTURA_LINEA`          |
| 117   | `cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA11` | `tvLineas2PRECIOVENTA_ARTICULO_LINEA`             |

---

## 3. Renombres en cascada: manejadores de evento

Estos métodos están listados como pendientes pero **se resuelven solos** al
renombrar la columna correspondiente (DevExpress regenera el nombre del
manejador a partir del nombre del componente):

| Fichero                   | Línea | Método actual                                                         | Tras renombrar la columna    |
|---------------------------|------:|-----------------------------------------------------------------------|------------------------------|
| `inMtoFacturas.pas`       | 485   | `tvLineasFacturaPRECIOSALIDA_FACTURA_LINEAPropertiesEditValueChanged` | Mismo nombre (la columna `tvLineasFacturaPRECIOSALIDA_FACTURA_LINEA` ya está OK; lo único largo es el sufijo BBDD) |
| `inMtoFacturas.pas`       | 939   | `TfrmMtoFacturas.ctbCODIGO_UNIDAD_FACTURA_LINEAPropertiesEditValueChanged` | Igual |
| `inMtoFacturas.pas`       | 1648  | `TfrmMtoFacturas.tvLineasFacturaPRECIO_DTO_FACTURA_LINEAPropertiesEditValueChanged` | Igual |
| `inMtoInventarios.pas`    | 489   | `TfrmMtoInventarios.cbbCODIGO_EMPRESA_INVENTARIOPropertiesEditValueChanged` | Igual |

> En estos cuatro el componente ya está bien nombrado (`tvLineasFactura`,
> `ctbXXX`, `cbbXXX`); lo que dispara la longitud es el **sufijo de la
> columna SQL**. Pasan a la sección §4.

---

## 4. Renombres de columnas SQL (encadena con `LIBRO_DE_ESTILO_BBDD.md`)

Solución de raíz: abreviar los sufijos de columna en BBDD siguiendo la
convención que ya usa el resto del esquema (`_FAC`, `_FACLIN`, `_INVLIN`,
`_ARTTAR`...). Esto **no es responsabilidad de este documento** porque
implica `ACTUALIZAR BBDD.txt`, scripts de migración y cambios en todos los
`FieldByName('...')`.

Propuesta para evaluar con el utilitario `src/utilnormbbdd/`:

| Sufijo actual                  | Sufijo propuesto    | Tablas afectadas                |
|--------------------------------|---------------------|---------------------------------|
| `_ARTICULO_FACTURA_LINEA`      | `_ARTFACLIN`        | `fza_facturas_lineas`           |
| `_FACTURA_LINEA`               | `_FACLIN`           | `fza_facturas_lineas`           |
| `_ARTICULO_LINEA`              | `_ARTLIN`           | varias tablas de líneas         |
| `_CLIENTE_FAC`                 | `_CLI_FAC`          | `fza_facturas_clientes`         |
| `_ARTICULO_INVENTARIO_LINEA`   | `_ARTINVLIN`        | `fza_inventarios_lineas`        |

Cada uno de estos baja entre 8 y 15 col las líneas largas y propaga el
cambio a los manejadores de evento de §3.

---

## 5. Casos aceptados (no se renombran)

### 5.1 URLs en comentarios

| Fichero                          | Línea | Razón                                                            |
|----------------------------------|------:|------------------------------------------------------------------|
| `src/Lib/IDETheme.ActnCtrls.pas` | 3     | URL de StackOverflow citada como fuente                          |
| `src/Lib/inLibIBAN.Types.pas`    | 27    | URL de artículo sobre cálculo del IBAN                           |

No se pueden partir sin romper el enlace. Quedan como están.

### 5.2 Comentarios decorativos `// =====`

Aparecen en `inLibCajaParam.pas`, `UniDataCaja.pas`, `inLibIBAN.pas` y
`inLibIBAN.Types.pas`. Son separadores visuales que generalmente miden 82-87
col. **Acción**: recortar el ancho del separador a **78 col** (deja margen
para que sigan siendo "una barra" visual sin pasar de 80). Cambio trivial
con un `sed` después de la pasada del wrap.

---

## 6. Plan de ejecución sugerido

1. **Renombrar las TV autogeneradas** en `inMtoGeneradorProcesos.dfm`
   (`tv2`, `tv3`). Requiere abrir el formulario en el IDE y decidir
   nombres semánticamente correctos. Es **el bloqueante de §2.4**.
2. **Renombrar las columnas** del §2 (4 formularios × 3-5 columnas =
   18 renombres). Hacerlo desde el Object Inspector del IDE para que
   DevExpress propague el cambio al `.dfm` y a los manejadores de evento
   del `.pas`. Verificar con `git diff` que no se rompe ningún
   `DataBinding.FieldName`.
3. **Acortar separadores decorativos** §5.2 (cambio trivial).
4. **Re-ejecutar `Ancho80`** sobre todo el árbol para regenerar wraps
   con los nombres nuevos (es probable que varias continuaciones de
   §1, fila *"intrínsecamente largas"*, ya no haga falta partirlas).
5. **Tarea aparte (no en este documento)**: renombrado de columnas SQL
   §4 — proyecto BBDD propio en `src/utilnormbbdd/`.

Estimación: pasos 1-3 → 1-2 h. Paso 4 → 5 min (ya está la herramienta).
Paso 5 → varios días, requiere coordinación con la BBDD de producción.

---

## 7. Cómo verificar el avance

```bash
# Antes
src/utilfmt80/Ancho80 -n -r src/  # cuenta los pendientes en simulación

# Después de cada renombrado
src/utilfmt80/Ancho80 src/Forms/inMtoFamilias.pas  # aplica al fichero
```

Objetivo: bajar de **113 → < 30** líneas pendientes (todas reducibles
sólo con cambios de BBDD §4 o con renombres del IDE §2.4).
