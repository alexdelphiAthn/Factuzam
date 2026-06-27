# Notas para Codex

Reglas y convenciones del repositorio Factuzam que cualquier sesión nueva
debe conocer antes de tocar nada. Lectura obligatoria al arrancar.

---

## Reglas duras (no negociables)

1. **NUNCA modificar `factuzam_original.sql`.** Es el dump modelo de la
   BBDD; se usa para crear instalaciones limpias desde cero. Cualquier
   cambio de esquema (ALTER, nuevas tablas, índices, columnas…) vive en
   un script idempotente dentro de `DESARROLLOS EN CURSO/` y se aplica
   por separado a las BBDD existentes. El día que se regenere
   `factuzam_original.sql` lo hará el usuario, no tú.

2. **Todo cambio de esquema es idempotente.** Patrón habitual: usar
   `INFORMATION_SCHEMA.COLUMNS` / `STATISTICS` / `TABLES` para comprobar
   si la columna / índice / tabla ya existe antes de crearla. Ver
   `DESARROLLOS EN CURSO/proveedores_nombre.sql` como ejemplo limpio.

3. **Idioma: español** en código, comentarios, mensajes y commits. Las
   excepciones (palabras reservadas Pascal, prefijos de bibliotecas de
   terceros `cx`/`dx`/`Jv`/`un`) están documentadas en
   `LIBRO_DE_ESTILO_DELPHI.md` §1.

4. **No commitees sin que te lo pidan.** Si trabajas en una sesión
   exploratoria, edita y deja que el usuario revise. Solo `git commit`
   cuando lo pidan explícitamente.

5. **No hagas push a `main`.** El branch de desarrollo está marcado en el
   prompt de sistema de la sesión (`Codex/<tema>-<id>`). Si no lo está,
   pregunta antes de crear branches o pushes.


---

## Convenciones del proyecto

Documentadas en detalle en:
- **`LIBRO_DE_ESTILO_BBDD.md`** — sufijos por tabla (`ART`, `CLI`, `FAC`…),
  prefijos de columna (`ESxxx_` booleanos, `INSTANTE_` datetimes,
  `FECHA_` dates, `PORCENTAJE_` floats…), reglas de FK lógicas, etc.
- **`LIBRO_DE_ESTILO_DELPHI.md`** — prefijos de unidad (`inMto*`,
  `inLib*`, `UniData*`), estructura de directorios `src/`, herencia
  obligatoria `TfrmBase` / `TfrmMtoGen`, máximo 80 columnas, etc.

Leelos antes de añadir tablas, columnas, unidades o formularios.

---

## Estructura del repo

```
factuzam_original.sql       ← BBDD modelo. NO TOCAR.
DESARROLLOS EN CURSO/       ← Cambios de esquema pendientes / WIP.
                              Scripts SQL idempotentes + .md de notas.
LIBRO_DE_ESTILO_BBDD.md     ← Convención SQL.
LIBRO_DE_ESTILO_DELPHI.md   ← Convención Pascal/VCL.
src/
├── Core/                   Forms troncales (Logon, Principal, Splash…)
├── Forms/                  Mantenimientos (inMto*)
├── Modals/                 Modales reutilizables
├── DataModules/            UniDAC data modules (UniData*)
├── Lib/                    Utilidades sin formulario (inLib*)
├── Lib3par/                Wrappers de 3rd party
├── verifactu/              Subsistema Verifactu (AEAT)
├── utilnormbbdd/           Util Delphi: normalizador de nombres BBDD
└── utilmigsqlsrv/          Util Delphi: migrador SQL Server → MariaDB
fzam.dpr / fzam.dproj       Proyecto principal Delphi VCL.
```

Las utilidades (`utilnormbbdd`, `utilmigsqlsrv`) son **proyectos Delphi
independientes** (`*.dpr` propio): no se compilan dentro de `fzam.dproj`.

---

## Stack técnico

- **Lenguaje**: Object Pascal / Delphi VCL.
- **BBDD destino**: MariaDB (compatible MySQL).
- **Acceso datos**: UniDAC de Devart. Provider `MySQL` (`TMySQLUniProvider`)
  para producción; `SQL Server` (`TSQLServerUniProvider`) para el
  migrador.
- **UI**: VCL + DevExpress (`cx*` / `dx*`) + JEDI (`Jv*`).
- **Reports**: FastReport (`frx*`).

No introduzcas dependencias nuevas sin justificación. No reemplaces
UniDAC por FireDAC ni nada parecido — es decisión arquitectónica.

---

## Patrones recurrentes

- **Auditoría**: toda tabla nueva incluye las 4 columnas estándar
  (`INSTANTE_ALTA`, `INSTANTE_MODIF`, `USUARIO_ALTA`, `USUARIO_MODIF`)
  sin sufijo de tabla. Detalle en `LIBRO_DE_ESTILO_BBDD.md` §3.7.
- **Booleanos**: `varchar(1)` con valores `'S'` / `'N'`. Columna
  con prefijo `ES` sin guión: `ESACTIVO_CLI`, `ESDEFAULT_FP`.
- **Commits "Auto-update YYYY-MM-DD …"**: los genera un workflow
  automatizado. **No** los crees tú; tu commit debe describir el cambio.
- **Orden de las instrucciones**: No meter en una misma linea dos instrucciones.
  por ejemplo if Hola <> '' then 
                Hola := 'Hola'; 
              while Adios <> 0 do 
                Adios := 'Adios'; //cada bucle e instrucción va en una linea. 
- **If, While y bucles**: Siempre en dos lineas, if, while o for y su 
  expresión en una linea y acción en otra. Evitar if (expresion) then token;
  en una sola linea.
- **Evitar Exit y Continue**: Aparte de ser malas prácticas de programación, 
  hacen que leer el código sea más difícil.
- **Orden en la declaración de clase (E2169)**: dentro de cada sección
  (`private`, `protected`, `public`, `published`) Delphi exige primero los
  **campos** (`FAlgo: TTipo;`) y solo después los **métodos** (`procedure` /
  `function`). Si insertas un campo nuevo, ponlo junto a los demás del bloque
  y no detrás de ningún `procedure`/`function` o el compilador lanzará
  E2169 "Field definition not allowed after methods or properties" y
  arrastrará un F2063 al usar la unit. Cuando añadas hooks (hook +
  variable de estado), declara primero los campos juntos y debajo los
  procedure que los usan.
- **Comentarios**: Dentro del código, hacer comentarios breves y útiles, 
  por ejemplo para delimitar bloques importantes, limitaciones, lineas
  a resaltar por lógica de negocio.
  **Lineas en blanco**: Evitar dejar lineas en blanco dentro de los bloques
  de código fuente y en los SQL.  
  **Controles nuevos**: Si se necesita meter controles nuevos en el código, serán preferentemente
  los de Developer Express TcxMemo TcxLabel, tcx....
---

## Cuándo preguntar

- Si el usuario te pide tocar una tabla o columna y no encuentras la
  convención en los libros de estilo (sufijo nuevo, prefijo nuevo), pide
  confirmación antes de inventártelos.
- Si vas a borrar / renombrar algo en producción (DELETE masivo, DROP,
  RENAME…), confirma antes y prepara también el rollback.
- Si una migración de datos puede tardar (cientos de miles de filas),
  avisa del orden de magnitud antes de lanzarla.
