# Ampliación en runtime de cualquier informe — “Guías” en `inMtoModalGenImp`

Notas de diseño sobre cómo permitir que **cualquier informe FastReport** del
programa exponga **columnas o tablas adicionales** sin recompilar el ejecutable
y sin tocar el `preparar_consulta` del modal hijo correspondiente.

La idea es generalizar el patrón ya estudiado para etiquetas en
`etiquetas_articulos_ampliacion_runtime.md`, pero modelándolo como un
**master-detail clásico de UniDAC**: `MasterSource` + `MasterFields` +
`DetailFields`. Cada "guía" es un dataset auxiliar que el usuario engancha al
dataset principal del informe por un par de campos (origen → destino), y queda
disponible en el `.frx` con su propio `TfrxDBDataset`.

---

## 1. El issue

Cada modal hijo de `TfrmPrint` (`TfrmPrintFac`, `TfrmPrintEtiqArt`,
`TfrmPrintSesion`, `TfrmPrintRecFac`, `TfrmPrintCliEti`, …) declara su propia
consulta dentro de `preparar_consulta` y expone los resultados al FastReport vía
uno o varios `TfrxDBDataset` cuyo `UserName` se referencia desde el `.frx`.

Hoy, si el usuario quiere mostrar en el ticket de una factura **el correo del
cliente** (que ya está en `fza_clientes` pero no en `vi_FACTURAS_print`), las
opciones son tres y las tres pasan por recompilar Delphi:

1. Ampliar la vista `vi_FACTURAS_print` para que arrastre el campo.
2. Añadir un `TUniQuery` y un `TfrxDBDataset` extra al `TdmFacturas` con la
   tabla `fza_clientes` y enlazarlo `MasterSource`-style.
3. Cambiar el `preparar_consulta` para que abra ese dataset adicional.

El usuario quiere poder hacerlo **desde Factuzam**, sin tocar Delphi: dar de
alta una "guía" para el informe `frmPrintFac` con `MasterFields=CODIGO_CLI_FAC`
→ `DetailFields=CODIGO_CLI` sobre `fza_clientes`, y volver a abrir el modal de
impresión para ver el nuevo dataset disponible en el diseñador FastReport.

---

## 2. Casos a cubrir

| Caso | Descripción                                                      | ¿Recompilar? |
|------|------------------------------------------------------------------|--------------|
| **A** — *Lookup por clave*. Ligar una tabla/vista existente al dataset principal del informe a través de un par de campos. El detalle se filtra automáticamente al navegar el master (igual que `MasterSource`/`MasterFields` de UniDAC). | **No**. |
| **B** — *Vista o SQL libre como dataset auxiliar*. La "guía" no apunta a una tabla, sino a un `SELECT …` arbitrario cuya cláusula `WHERE` contiene parámetros que el motor rellena con los campos del master. | **No** (con cautelas, ver §6). |
| **C** — *Ampliar la vista del informe* añadiéndole columnas calculadas (caso B del MD de etiquetas). | **No** para vistas pivotadas tipo etiquetas; **sí** para informes con SQL escrito en Delphi (porque la query la construye el modal hijo). |
| **D** — Reemplazar el dataset principal del informe por uno totalmente distinto, cambiar agrupaciones, parámetros nuevos en el .frx, … | **Sí**. Fuera de alcance. |

Lo más realista es **resolver A y B**. El caso C ya está cubierto por el doc de
etiquetas. El D queda fuera del alcance.

---

## 3. Modelo de datos

Tabla nueva `fza_informes_guias`, sufijo `INFGUI` (acrónimo de
*INForme-GUIa*; sigue el patrón `fza_usuarios_perfiles → USUPER`).

```sql
CREATE TABLE `fza_informes_guias` (
  `CODIGO_INFGUI`         varchar(40)  NOT NULL,        -- nombre lógico (UserName del frxDBDataset)
  `INFORME_INFGUI`        varchar(100) NOT NULL,        -- Self.Name del TfrmPrint (p.ej. 'frmPrintFac')
  `DATASET_MASTER_INFGUI` varchar(100) NOT NULL,        -- UserName del TfrxDBDataset master del informe
  `TIPO_INFGUI`           varchar(10)  NOT NULL,        -- 'TABLA' | 'SQL'
  `TABLA_INFGUI`          varchar(60)  DEFAULT NULL,    -- relleno si TIPO='TABLA'
  `SQL_INFGUI`            text         DEFAULT NULL,    -- relleno si TIPO='SQL'
  `MASTER_FIELDS_INFGUI`  varchar(200) NOT NULL,        -- campos del master, separados por ';'
  `DETAIL_FIELDS_INFGUI`  varchar(200) NOT NULL,        -- campos del detail correspondientes, separados por ';'
  `ORDEN_INFGUI`          int(11)      NOT NULL DEFAULT 0,
  `ESACTIVO_INFGUI`       varchar(1)   NOT NULL DEFAULT 'S',
  `INSTANTE_ALTA`         datetime     NOT NULL,
  `USUARIO_ALTA`          varchar(50)  NOT NULL,
  `INSTANTE_MODIF`        datetime     DEFAULT NULL,
  `USUARIO_MODIF`         varchar(50)  DEFAULT NULL,
  PRIMARY KEY (`CODIGO_INFGUI`)
);

ALTER TABLE `fza_informes_guias`
  ADD INDEX `IDX_INFGUI_INFORME` (`INFORME_INFGUI`);
```

Notas sobre las columnas:

- `CODIGO_INFGUI` es el **nombre lógico** que se usa como `UserName` del
  `TfrxDBDataset` que crearemos en runtime y, por tanto, lo que el usuario
  escribirá en el `.frx` (`[<CODIGO_INFGUI>."<columna>"]`). Conviene exigir
  un patrón `^[A-Za-z][A-Za-z0-9_]*$` para que sea identificador válido
  dentro de FastReport.
- `INFORME_INFGUI` identifica el modal hijo. Misma idea que `KEY_USUPER` en
  `fza_usuarios_perfiles`. Si el usuario quiere reutilizar la misma guía
  en varios informes, **se duplica el registro**: simple y trazable.
- `DATASET_MASTER_INFGUI` es el `UserName` del dataset principal de ese
  informe. Cada modal hijo debe declarar uno por convención (hoy ya lo
  hacen — `fxdsPrintFac`, `fxdsEtiquetasArt`, `fxdsRecibos`, etc.). El
  modal de mantenimiento ofrece un combo con los `UserName` disponibles en
  el `TfrxReport` para evitar errores.
- `TIPO_INFGUI = 'TABLA'`: el detail abre la tabla o vista de
  `TABLA_INFGUI` filtrada por la clave del master (filtrada vía UniDAC,
  no en el SQL).
- `TIPO_INFGUI = 'SQL'`: el detail ejecuta el SQL de `SQL_INFGUI` con
  parámetros nombrados por los campos del master. Permite agregaciones,
  joins, expresiones — al precio de validar el SQL antes de aceptarlo.
- `MASTER_FIELDS_INFGUI` / `DETAIL_FIELDS_INFGUI` siguen literalmente la
  semántica de UniDAC: pares ordenados separados por `;`. Ejemplo:
  - master `CODIGO_CLI_FAC` ↔ detail `CODIGO_CLI`.
  - master `NUMERO_FAC;SERIE_FAC` ↔ detail `NUMERO_FAC_REC;SERIE_FAC_REC`.
- `ORDEN_INFGUI` permite que el modal abra varias guías en un orden
  determinado, por si una guía dependiera de los resultados de otra
  (escenarios poco frecuentes pero posibles).

---

## 4. Cambios en `inMtoModalGenImp`

### 4.1 Botón nuevo "Guías"

En `inMtoModalGenImp.dfm`, dentro de `pnl1` se añade un `cxButton btnGuias`
entre `btnEditar` (Top=72) y `btnImprimir` (Top=120). Resto de botones se
desplazan hacia abajo. Patrón visual idéntico a los existentes (`Caption =
'&Guías'`, `OnClick = btnGuiasClick`).

```pascal
TfrmPrint = class(TfrmBase)
  …
  btnGuias: TcxButton;
  unqryGuias: TUniQuery;  // SELECT * FROM fza_informes_guias WHERE INFORME_INFGUI = :Inf …
  procedure btnGuiasClick(Sender: TObject);
public
  // Hook llamado por btnVistaPreliminar/btnPDF/btnImprimir/btnExcel
  // antes de AfterReportLoaded.
  procedure AbrirGuiasRuntime; virtual;
  // Hook simétrico para cerrar y liberar los datasets creados runtime.
  procedure CerrarGuiasRuntime;
end;
```

`btnGuiasClick` abre el mantenimiento `TfrmMtoInformesGuias` (sección 5)
filtrado por `Self.Name`.

### 4.2 Apertura runtime de las guías

`AbrirGuiasRuntime` recorre `fza_informes_guias` para `INFORME_INFGUI =
Self.Name` y `ESACTIVO_INFGUI = 'S'`. Por cada fila:

1. Localiza dentro de `frxrprt1.Datasets` (o, si se usa
   `RebindReportDataSetsByDataModule`, dentro del data module pasado a esa
   rutina) el `TfrxDBDataset` cuyo `UserName` coincide con
   `DATASET_MASTER_INFGUI`. Si no existe, se ignora la guía y se logea
   warning (`inLibLog`).
2. Crea en memoria, owned por `Self`, un trío:
   - `TUniQuery` con `Connection := oConn`.
   - `TDataSource` apuntando al `DataSet` del master frxDBDataset (su `.DataSet` siempre es un `TDataSet` válido tras `preparar_consulta`).
   - `TfrxDBDataset` con `UserName := CODIGO_INFGUI`, `DataSet := <UniQuery>`.
3. Configura el `TUniQuery`:
   - Si `TIPO_INFGUI = 'TABLA'`:
     - `SQL.Text := 'SELECT * FROM ' + TABLA_INFGUI`.
     - `MasterSource := <DataSource creado>`,
     - `MasterFields := MASTER_FIELDS_INFGUI`,
     - `DetailFields := DETAIL_FIELDS_INFGUI`.
   - Si `TIPO_INFGUI = 'SQL'`:
     - `SQL.Text := SQL_INFGUI` tal cual.
     - Los `MasterFields`/`DetailFields` se traducen a parámetros con el
       mismo nombre, equivalente a lo que hace UniDAC internamente.
4. Añade el `TfrxDBDataset` recién creado a `frxrprt1.Datasets`. El usuario
   del `.frx` ya lo ve aparecer en el diseñador.
5. `unqry.Open`. Si falla, captura excepción, logea, y la guía se desactiva
   para esta impresión (no bloquea el resto).

`CerrarGuiasRuntime` libera los tres componentes en orden inverso. Se llama
al cerrar el modal o antes de cualquier nueva impresión, para evitar
acumular datasets entre tiradas.

### 4.3 Punto de inserción exacto

En todos los handlers de los botones (`btnImprimirClick`, `btnPDFClick`,
`btnVistaPreliminarClick`, `btnExcelClick`, `btnEditarClick`) el orden pasa
de:

```pascal
Preparar_consulta;
Self.Hide;
Consultar_Formularios;
if (sElegido <> '') then
begin
  AfterReportLoaded;
  frxrprt1.PrepareReport(True);
  …
end;
```

a:

```pascal
Preparar_consulta;
Self.Hide;
Consultar_Formularios;
if (sElegido <> '') then
begin
  AfterReportLoaded;
  AbrirGuiasRuntime;                    //  ←  NUEVO
  try
    frxrprt1.PrepareReport(True);
    …
  finally
    CerrarGuiasRuntime;                 //  ←  NUEVO
  end;
end;
```

Es importante que `AbrirGuiasRuntime` se invoque **después** de
`AfterReportLoaded`, porque el hook
`RebindReportDataSetsByDataModule` borra y rehace `frxrprt1.Datasets` y, si
añadimos las guías antes, se las cargaría por delante.

---

## 5. Mantenimiento `TfrmMtoInformesGuias`

Hereda de `TfrmMtoGen` (patrón estándar del proyecto). Pestaña única con un
grid sobre `fza_informes_guias` filtrado por `INFORME_INFGUI = :Inf`,
parámetro fijado al abrir el form desde `btnGuiasClick`.

Campos visibles en el grid:

| Columna             | Comentario                                                  |
|---------------------|-------------------------------------------------------------|
| `CODIGO_INFGUI`     | Nombre lógico (=UserName del dataset).                      |
| `DATASET_MASTER_INFGUI` | Combo populado con los `UserName` del `frxrprt1` del informe que abrió la guía. |
| `TIPO_INFGUI`       | Radio TABLA / SQL.                                          |
| `TABLA_INFGUI`      | Combo con lista de tablas/vistas del esquema (`information_schema.tables` filtrado por prefijo `fza_`/`vi_`). Sólo activo si TIPO=TABLA. |
| `SQL_INFGUI`        | Memo SQL. Sólo activo si TIPO=SQL.                          |
| `MASTER_FIELDS_INFGUI` | Texto separado por `;`. Idealmente con un editor que liste los campos del master. |
| `DETAIL_FIELDS_INFGUI` | Texto separado por `;`. Misma idea para el detail. |
| `ORDEN_INFGUI`      | Entero.                                                     |
| `ESACTIVO_INFGUI`   | Booleano S/N.                                               |

Validaciones en `BeforePost`:

- `CODIGO_INFGUI REGEXP '^[A-Za-z][A-Za-z0-9_]*$'`.
- `CODIGO_INFGUI` no choca con un `UserName` ya existente en `frxrprt1`.
- Si `TIPO_INFGUI = 'TABLA'`, `TABLA_INFGUI` existe en el esquema (consulta a
  `information_schema.tables`).
- Si `TIPO_INFGUI = 'SQL'`, `SQL_INFGUI` compila — se intenta `PREPARE` y se
  hace `LIMIT 0` para verificar.
- Número de tokens en `MASTER_FIELDS_INFGUI` y `DETAIL_FIELDS_INFGUI`
  coincide (ambos separados por `;`).

Por permisos, este mantenimiento se restringe al grupo administrador
(`orootGroup = 'S'`) para evitar que un usuario sin contexto SQL meta
expresiones costosas o equivocadas.

---

## 6. Riesgos y mitigaciones

| Riesgo | Mitigación |
|--------|------------|
| Inyección SQL en `SQL_INFGUI`. | Acceso restringido a grupo admin. `BeforePost` valida que la query compila. Mejor: aceptar sólo `SELECT` (rechazar `;`, `--`, `INSERT`, `UPDATE`, `DELETE`). |
| `CODIGO_INFGUI` choca con un `UserName` existente del informe. | Validación en `BeforePost` y, defensivamente, en `AbrirGuiasRuntime`: si choca, se ignora la guía y se logea. |
| El master pasa a estar cerrado entre tiradas, los datasets de guía quedan apuntando a un `TDataSource` con `DataSet=nil`. | `CerrarGuiasRuntime` se llama en el `finally` y en `FormClose`. |
| `MASTER_FIELDS_INFGUI` apunta a un campo que no existe en el dataset master (porque el SQL del informe cambia en runtime, p.ej. `vi_FACTURAS_print` evoluciona). | UniDAC lanza excepción al hacer `Open` del detail; se captura por guía, se logea, no bloquea el informe. |
| El usuario añade muchas guías y la impresión se lentifica. | Las guías son LEFT-equivalentes y se ejecutan por master record vía el cursor de UniDAC — coste lineal. Si llega a ser problema, paginar/cachear; ahora no es prioritario. |
| La guía abre datos que el usuario no debería ver (p.ej. costes). | Mismo modelo de permisos que el resto del programa: las tablas con datos sensibles ya están protegidas a nivel de aplicación. Conviene documentar que las guías heredan el ámbito de visibilidad del usuario. |

---

## 7. Ejemplo paso a paso

Escenario: el ticket de factura hoy NO muestra el email del cliente porque
`vi_FACTURAS_print` no lo expone. Lo añadimos vía guía.

### 7.1 Estado inicial

```sql
mysql> SELECT * FROM vi_FACTURAS_print LIMIT 1;
+-----------+--------------+----------------+-----------+ …
| SERIE_FAC | NUMERO_FAC   | CODIGO_CLI_FAC | TOTAL_FAC | …
+-----------+--------------+----------------+-----------+
| A         |          123 | C0001          |     150.0 | …
```

No hay email. La tabla `fza_clientes` sí lo tiene: `EMAIL_CLI`,
`CODIGO_CLI`.

### 7.2 Alta de la guía

Desde `frmPrintFac` → botón **Guías**. Se abre `TfrmMtoInformesGuias`
prefiltrado por `INFORME_INFGUI = 'frmPrintFac'`. El usuario pulsa "Nuevo"
y rellena:

| Campo                    | Valor                  |
|--------------------------|------------------------|
| `CODIGO_INFGUI`          | `ClienteFac`           |
| `DATASET_MASTER_INFGUI`  | `fxdsPrintFac`         |
| `TIPO_INFGUI`            | `TABLA`                |
| `TABLA_INFGUI`           | `fza_clientes`         |
| `MASTER_FIELDS_INFGUI`   | `CODIGO_CLI_FAC`       |
| `DETAIL_FIELDS_INFGUI`   | `CODIGO_CLI`           |
| `ORDEN_INFGUI`           | `1`                    |
| `ESACTIVO_INFGUI`        | `S`                    |

Guarda. La fila queda persistida — equivale a esta línea SQL detrás:

```sql
INSERT INTO fza_informes_guias VALUES
  ('ClienteFac', 'frmPrintFac', 'fxdsPrintFac', 'TABLA', 'fza_clientes',
   NULL, 'CODIGO_CLI_FAC', 'CODIGO_CLI', 1, 'S',
   NOW(), 'Admin', NOW(), 'Admin');
```

### 7.3 Edición del .frx

Cierra el mantenimiento, vuelve a `frmPrintFac`, pulsa **Editar**. Se abre
el diseñador FastReport con el `.frx` actual. En el árbol de datasets
**aparece un nuevo dataset llamado `ClienteFac`** con todas las columnas
de `fza_clientes` (`NIF_CLI`, `NOMBRE_CLI`, `EMAIL_CLI`, …) porque
`AbrirGuiasRuntime` ya hizo el `Open` antes de invocar al diseñador.

El usuario arrastra una `Memo` a la cabecera de página con:

```
[ClienteFac."EMAIL_CLI"]
```

Guarda el `.frx` con el sistema de perfiles del programa.

### 7.4 Verificación

Pulsa **Vista Preliminar**: para cada factura del rango, el motor de UniDAC
filtra automáticamente `fza_clientes` por `CODIGO_CLI = CODIGO_CLI_FAC` (es
master-detail puro), el `.frx` resuelve `[ClienteFac."EMAIL_CLI"]` con el
email del cliente correspondiente, y aparece en el ticket. **Cero
recompilación.**

### 7.5 Coste y reversibilidad

- Cada guía añade un dataset adicional al informe. Coste de apertura por
  factura: 1 consulta filtrada por PK indexado (`CODIGO_CLI` en
  `fza_clientes`).
- Si una guía rompe (campo inexistente, tabla renombrada), el log lo
  recoge y la impresión sigue. La memo `[ClienteFac."EMAIL_CLI"]` queda en
  blanco — el usuario sabe que algo no va y reabre el mantenimiento.
- Para revertir: `ESACTIVO_INFGUI = 'N'` en esa guía. Se conserva la
  configuración pero deja de aplicarse.

---

## 8. Hoja de ruta sugerida

1. **DDL** de `fza_informes_guias` en un script propio dentro de
   `DESARROLLOS EN CURSO/informes_guias.sql`.
2. **Mantenimiento** `inMtoInformesGuias.pas/.dfm` heredando de `inMtoGen`,
   con las validaciones de §5.
3. **Cambios en `inMtoModalGenImp`**:
   - Nuevo botón `btnGuias` y handler `btnGuiasClick`.
   - Métodos `AbrirGuiasRuntime` / `CerrarGuiasRuntime`.
   - Inserción de `AbrirGuiasRuntime` / `CerrarGuiasRuntime` en los cinco
     handlers de impresión.
   - `TUniQuery` y `TDataSource` auxiliares (creados runtime, no en .dfm).
4. **Entrada en el menú de Factuzam** para abrir
   `TfrmMtoInformesGuias` de forma standalone (admins). Aparte del
   acceso contextual desde el botón "Guías" del modal de impresión.
5. **Smoke test**: dar de alta la guía `ClienteFac` y probar a imprimir
   una factura con `[ClienteFac."EMAIL_CLI"]` desde `.frx`. Repetir con
   `TIPO_INFGUI = 'SQL'` y una expresión agregada.

Con la 1, 2 y 3 hechas, queda cubierto el 95 % de los "me falta este campo
en el informe" sin recompilar ni desplegar parche.

---

## 9. Anexo — diferencias con `etiquetas_articulos_ampliacion_runtime.md`

- Aquel doc resuelve un problema **específico**: la vista de etiquetas
  tiene columnas pivotadas hardcoded (`PROP_MARCA`, `ATR_CO`, …). La
  solución es un SP que regenera la vista — vive a nivel de SQL, no toca
  el frontend del informe.
- Este doc resuelve un problema **transversal**: cualquier informe puede
  necesitar columnas de tablas que no estaban en su consulta original.
  La solución vive a nivel del modal de impresión y se modela como
  master-detail estilo UniDAC.
- Ambas estrategias son **complementarias**: una guía sobre la vista de
  etiquetas se beneficia del SP que la mantiene viva.
